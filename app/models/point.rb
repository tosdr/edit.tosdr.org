# frozen_string_literal: true

# app/models/point.rb
class Point < ApplicationRecord
  has_paper_trail

  belongs_to :user, optional: true
  belongs_to :topic, optional: true
  belongs_to :document, optional: true
  belongs_to :service
  belongs_to :case
  has_many :point_comments, dependent: :destroy

  validates :title, presence: true
  validates :status,
            inclusion: { in: %w[approved pending declined changes-requested draft approved-not-found pending-not-found],
                         allow_nil: false }
  validates :case_id, presence: true

  scope :eager_loaded, -> { includes(:case, :service, :user) }
  scope :user_reviewable, ->(users) { where.not(user_id: users) }
  scope :need_review, ->(status) { where(status: status) }
  scope :docbot_created, ->(user) { where(user_id: user) }
  scope :current_user_points, ->(user) { where(user_id: user) }

  def self.pending(users)
    Point.eager_loaded
         .user_reviewable(users)
         .need_review(%w[pending approved-not-found])
         .order(updated_at: :asc)
         .limit(10)
         .offset(rand(100))
  end

  def self.docbot
    docbot_user = User.find_by_username('docbot')
    Point.eager_loaded
         .docbot_created(docbot_user.id)
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
