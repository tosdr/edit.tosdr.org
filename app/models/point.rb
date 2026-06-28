# frozen_string_literal: true

# app/models/point.rb
class Point < ApplicationRecord
  has_paper_trail

  AUTO_APPROVAL_WAIT = 7.days
  AUTO_APPROVAL_MAX_AGE = 6.months
  VETO_THRESHOLD = 3

  belongs_to :user, optional: true
  belongs_to :topic, optional: true
  belongs_to :document, optional: true
  belongs_to :service
  belongs_to :case
  has_many :point_comments, dependent: :destroy
  has_many :point_vetoes, dependent: :destroy

  # Title presence is grandfathered: enforced on create and when the title is being changed,
  # but a pre-existing point that leaves it untouched can still be saved/edited so legacy
  # blank-title rows are not stuck. status and case_id (referential) stay strict.
  validates :title, presence: true, unless: -> { persisted? && !title_changed? }
  validates :status,
            inclusion: { in: %w[approved pending declined changes-requested draft approved-not-found pending-not-found deleted],
                         allow_nil: false }
  validates :case_id, presence: true

  # Soft-delete: deprecated points have status 'deleted' and are hidden from every
  # read path. The predicate is NULL-safe (a plain `where.not` would drop NULL rows).
  default_scope { where("status IS DISTINCT FROM 'deleted'") }

  # Allows us to bypass the filtering of deleted points. This is used by deprecate_orphans below,
  # and might be useful for ad hoc admin/debugging sessions where we want to see all points.
  def self.with_deleted
    unscoped
  end

  # Deprecate any still-active point whose service or document is already deprecated. 
  # Covers orphans created before the service cascade handled document-less points, 
  # and services/documents marked 'deleted' directly in the DB. Idempotent.
  # Uses update_all rather than update! because a point under a deprecated service
  # cannot pass the required `belongs_to :service` validation (the service is hidden by the default scope).
  def self.deprecate_orphans!
    deleted_services = Service.unscoped.where(status: 'deleted').select(:id)
    deleted_documents = Document.unscoped.where(status: 'deleted').select(:id)

    active = with_deleted.where.not(status: 'deleted')
    orphan_ids = active.where(service_id: deleted_services)
                       .or(active.where(document_id: deleted_documents))
                       .pluck(:id)
    return if orphan_ids.empty?

    author_ids = with_deleted.where(id: orphan_ids).distinct.pluck(:user_id).compact
    with_deleted.where(id: orphan_ids).update_all(status: 'deleted')
    # Author levels are refreshed afterwards since that callback is skipped by update_all
    User.where(id: author_ids).find_each(&:refresh_level_from_points!)
  end

  # Soft-delete this point as part of a service/document deprecation cascade. Skips
  # validations (via save!(validate: false)) so legacy points with otherwise-invalid
  # content -- a blank title, a missing case, or a service already hidden by its default
  # scope -- can still be hidden. Keeps callbacks + PaperTrail, unlike update_all.
  def deprecate!
    self.status = 'deleted'
    save!(validate: false)
  end

  before_validation :set_verified_contributor_auto_approval
  after_commit :refresh_author_levels_after_commit, on: %i[create update]
  after_destroy_commit :refresh_destroyed_author_level

  scope :eager_loaded, -> { includes(:case, :service, :user) }
  scope :eager_loaded_nouser, -> { includes(:case, :service) }

  def self.ransackable_associations(auth_object = nil)
    ["service", "case"]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title status analysis source]
  end
  scope :user_reviewable, ->(users) { where.not(user_id: users) }
  scope :need_review, ->(status) { where(status: status) }
  scope :docbot_created, ->(user) { where(user_id: user) }
  scope :current_user_points, ->(user) { where(user_id: user) }

  def self.auto_approve_veto_expired(now: Time.current)
    joins(:user)
      .where(status: 'pending')
      .where(users: { verified_contributor: true })
      .where('points.created_at >= ?', AUTO_APPROVAL_MAX_AGE.ago)
      .where('points.auto_approve_after <= ?', now)
      .find_each do |point|
        point.auto_approve_from_veto_period!
      end
  end

  def self.pending(users)
    Point.eager_loaded
         .user_reviewable(users)
         .need_review(%w[pending approved-not-found])
         .order(updated_at: :asc)
         .limit(10)
         .offset(rand(100))
  end

  def self.docbot(include_user: true)
    docbot_user = User.docbot_user
    base = include_user ? eager_loaded : eager_loaded_nouser
    base.docbot_created(docbot_user.id)
        .need_review('pending')
        .limit(10)
        .order('ml_score DESC')
  end

  def self.draft(user)
    Point.eager_loaded
         .current_user_points(user)
         .need_review('draft')
         .limit(10)
  end

  def self.changes_requested(user)
    Point.eager_loaded
         .current_user_points(user)
         .need_review('changes-requested')
         .limit(10)
  end

  def self.search_points_by_multiple(query)
    Point.joins(:service).where('services.name ILIKE ? or points.status ILIKE ? OR points.title ILIKE ?', "%#{query}%",
                                "%#{query}%", "%#{query}%")
  end

  def auto_approval_countdown?
    status == 'pending' &&
      auto_approve_after.present? &&
      user&.verified_contributor? &&
      eligible_for_verified_contributor_auto_approval?
  end

  def auto_approval_remaining(now: Time.current)
    return 0 unless auto_approval_countdown?

    [auto_approve_after - now, 0].max
  end

  def auto_approve_from_veto_period!
    transaction do
      update!(status: 'approved', auto_approve_after: nil)
      point_comments.create!(
        summary: 'Point automatically approved after the 7 day verified contributor veto period.',
        user: user
      )
    end
  end

  def veto_period_veto!(voter)
    return :ineligible unless voter&.level_two?
    return :own_point if voter.id == user_id
    return :not_in_veto_period unless auto_approval_countdown?

    transaction do
      lock!
      return :not_in_veto_period unless auto_approval_countdown?

      point_vetoes.find_or_create_by!(user: voter)

      if point_vetoes.count >= VETO_THRESHOLD
        update!(status: 'changes-requested', auto_approve_after: nil)
        point_comments.create!(
          summary: 'Changes requested after 3 level 2 contributor veto votes.',
          user: voter
        )
        :changes_requested
      else
        :veto_recorded
      end
    end
  rescue ActiveRecord::RecordNotUnique
    :veto_recorded
  end

  def restore
    quote_start = document.text.index(quote_text)
    quote_end = quote_start + quote_text.length
    self.quote_start = quote_start
    self.quote_end = quote_end
    save
  end

  def restore_elasticsearch
    return unless annotation_ref

    uuid = annotation_uuid

    annotation = Annotation.find(uuid)
    annotation = annotation.restore

    migrate if annotation
  end

  def self.retrieve_annotation(id)
    retrieve_by_annotation_uuid(id)
  end

  # uuid - d8084a2c-c98b-11ed-bfb9-5341372e7080 - what's stored in h's annotation table
  # url-safe string from uuid (computed by h) - 2AhKLMmLEe2_uVNBNy5wgA - what we're sent from client
  def self.retrieve_by_annotation_uuid(id)
    uuid = StringConverter.new(string: id).to_uuid
    sql = ApplicationRecord.sanitize_sql(["SELECT * FROM annotation WHERE id = '%s'", uuid])
    annotation = execute_statement(sql)
    annotation[0]
  end

  def self.execute_statement(sql)
    results = ActiveRecord::Base.connection.exec_query(sql)
    results = nil unless results.present?
    results
  end

  def update_annotation(new_target_uri, new_target_uri_normalized, annotation)
    id = annotation['id']
    # Step 1: Prepare the SQL statement
    sql = <<-SQL
      UPDATE annotation
      SET target_uri = $1,
          target_uri_normalized = $2
      WHERE id = $3;
    SQL

    # Step 2: Execute the SQL statement
    begin
      result = ActiveRecord::Base.connection.exec_query(sql, 'SQL',
                                                        [[nil, new_target_uri], [nil, new_target_uri_normalized], [nil, id]])
      puts "#{result.rows.count} record(s) updated successfully!" if result.rows.count > 0
    rescue ActiveRecord::StatementInvalid => e
      puts "An error occurred: #{e.message}"
    end
  end

  def dynamic_update(table_name, id, updates)
    # Step 1: Build the SET clause dynamically
    set_clause = updates.map do |column, value|
      "#{ActiveRecord::Base.connection.quote_column_name(column)} = #{ActiveRecord::Base.connection.quote(value)}"
    end.join(', ')

    # Step 2: Prepare the SQL statement
    sql = "UPDATE #{ActiveRecord::Base.connection.quote_table_name(table_name)} SET #{set_clause} WHERE id = #{ActiveRecord::Base.connection.quote(id)};"

    # Step 3: Execute the SQL statement
    begin
      result = ActiveRecord::Base.connection.exec_query(sql)
      puts "#{result.rows.count} record(s) updated successfully!" if result.rows.count > 0
    rescue ActiveRecord::StatementInvalid => e
      puts "An error occurred: #{e.message}"
    end
  end

  # # Example usage
  # updates = {
  #   target_uri: annotation['target_uri'].gsub('https://edit.tosdr.org', 'http://localhost:9090'),
  #   target_uri_normalized: annotation['target_uri_normalized'].gsub('httpx://edit.tosdr.org', 'httpx://localhost:9090')
  # }

  # dynamic_update('annotation', annotation['id'], updates)

  def migrate
    # only creates new annotation if point is not already linked to an annotation
    unless annotation_ref
      annotation = create_annotation_in_db
      annotation = link_annotation(annotation)
    end

    uuid = annotation_uuid
    # does not perform the migration if point's annotation_ref does not exist

    annotation = Annotation.find(uuid) if annotation_ref && Annotation.find(uuid).present?

    if annotation_ref && !Annotation.find(uuid).present?
      puts `MIGRATION: point #{id} has annotation_ref but no corresponding annotation`
    end

    annotation.index_elasticsearch
  end

  def display_title
    return self.case&.title if self.case

    point.quote_text ? '"' + point.quote_text + '"' : point.title
  end

  def annotation_uuid
    StringConverter.new(string: annotation_ref).to_uuid
  end

  def build_target_selectors
    target_selectors = []
    target_selectors << {
      'type' => 'RangeSelector',
      'endOffset' => nil,
      'startOffset' => nil,
      'endContainer' => nil,
      'startContainer' => nil
    }
    target_selectors << { 'end' => nil, 'type' => 'TextPositionSelector', 'start' => nil }
    exact = quote_text
    document_text = document.text
    prefix = document_text[quote_start - 31...quote_start]
    suffix = document_text[quote_end...quote_end + 31]
    target_selectors << { 'type' => 'TextQuoteSelector', 'exact' => exact, 'prefix' => prefix, 'suffix' => suffix }
    target_selectors
  end

  def build_annotation
    document_id = retrieve_annotation_document_id
    {
      userid: 'acct:' + user.normalize_username + '@' + ENV['AUTHORITY'],
      groupid: '__world__',
      tags: [] << self.case.title,
      shared: true,
      target_uri: determine_target_uri(self),
      target_uri_normalized: determine_target_uri_normalized(self),
      target_selectors: build_target_selectors,
      references: [],
      extra: { 'serviceId' => service.id.to_s, 'documentId' => document_id.to_s },
      deleted: false,
      document_id: document_id
    }
  end

  def create_annotation_in_db
    attrs = build_annotation
    transaction do
      annotation = Annotation.new(attrs)
      annotation.save!
      annotation.reload
      annotation
    end
  rescue ActiveRecord::RecordInvalid => e
    puts `MIGRATION ERROR for #{id} at annotation creation: #{e.record.errors}`
  end

  def retrieve_annotation_document_id
    target_uri = determine_target_uri(self)
    annotations_at_target = Annotation.where(target_uri: target_uri)
    h_docs_at_target_uri = HDocument.where(web_uri: target_uri)

    if annotations_at_target.present?
      annotations_at_target.pluck(:document_id).uniq[0]
    elsif h_docs_at_target_uri.present?
      h_docs_at_target_uri.first.id
    else
      # create document in H -__-
      h_document = HDocument.new(title: 'Terms of Service; Didn\'t Read - Phoenix', web_uri: determine_target_uri(self))
      h_document.save!
      h_document.reload
      h_document.id
    end
  end

  def link_annotation(annotation)
    transaction do
      ref = StringConverter.new(string: annotation.id).to_url_safe
      update!(annotation_ref: ref)
      annotation.reload
      annotation
    end
  rescue ActiveRecord::RecordInvalid => e
    puts `MIGRATION ERROR for #{id} at link annotation: #{e.record.errors}`
  end

  private

  def refresh_author_levels_after_commit
    user_ids = []
    user_ids << user_id if saved_change_to_status? || saved_change_to_user_id?

    if saved_change_to_user_id?
      old_user_id, = saved_change_to_user_id
      user_ids << old_user_id
    end

    refresh_user_levels(user_ids)
  end

  def refresh_destroyed_author_level
    refresh_user_levels([user_id])
  end

  def refresh_user_levels(user_ids)
    User.where(id: user_ids.compact.uniq).find_each(&:refresh_level_from_points!)
  end

  def set_verified_contributor_auto_approval
    if status == 'pending' && user&.verified_contributor? && eligible_for_verified_contributor_auto_approval?
      self.auto_approve_after ||= AUTO_APPROVAL_WAIT.from_now
    else
      self.auto_approve_after = nil
    end
  end

  def eligible_for_verified_contributor_auto_approval?
    return true if created_at.blank?

    created_at >= AUTO_APPROVAL_MAX_AGE.ago
  end

  def determine_target_uri(point)
    path = Rails.application.routes.url_helpers.service_url(point.service, only_path: true)
    # this is really bad but we need to do it for the migration
    if Rails.env == 'development'
      'http://' + ENV['AUTHORITY'] + ':' + ENV['WEB_PORT'] + path + '/annotate'
    else
      'https://' + ENV['AUTHORITY'] + path + '/annotate'
    end
  end

  def determine_target_uri_normalized(point)
    # this is really bad but we need to do it for the migration
    path = Rails.application.routes.url_helpers.service_url(point.service, only_path: true)
    if Rails.env == 'development'
      'httpx://' + ENV['AUTHORITY'] + ':' + ENV['WEB_PORT'] + path + '/annotate'
    else
      'httpx://' + ENV['AUTHORITY'] + path + '/annotate'
    end
  end
end
