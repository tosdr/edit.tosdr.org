# frozen_string_literal: true

class Point < ApplicationRecord
  has_paper_trail
  belongs_to :user, optional: true
  belongs_to :topic, optional: true
  belongs_to :document, optional: true

  belongs_to :service
  belongs_to :case

  has_many :point_comments, dependent: :destroy

  validates :title, presence: true
  validates :title, presence: true
  validates :status, inclusion: { in: %w[approved pending declined changes-requested draft approved-not-found pending-not-found], allow_nil: false }
  validates :case_id, presence: true

  def self.search_points_by_multiple(query)
    Point.joins(:service).where('services.name ILIKE ? or points.status ILIKE ? OR points.title ILIKE ?', "%#{query}%", "%#{query}%", "%#{query}%")
  end

  def restore
    quote_start = document.text.index(quote_text)
    quote_end = quote_start + quote_text.length
    self.quote_start = quote_start
    self.quote_end = quote_end
    save
  end

  def self.retrieve_annotation(id)
    retrieve_by_annotation_uuid(id)
  end

  # uuid - d8084a2c-c98b-11ed-bfb9-5341372e7080 - what's stored in h's annotation table
  # url-safe string from uuid (computed by h) - 2AhKLMmLEe2_uVNBNy5wgA - what we're sent from client
  def self.retrieve_by_annotation_uuid(id)
    uuid = determine_uuid(id)
    sql = ApplicationRecord.sanitize_sql(["SELECT * FROM annotation WHERE id = '%s'", uuid])
    annotation = execute_statement(sql)
    annotation[0]
  end

  def self.execute_statement(sql)
    results = ActiveRecord::Base.connection.exec_query(sql)
    results = nil unless results.present?
    results
  end

  def migrate
    unless annotation_ref
      annotation = create_annotation_in_db
      annotation = link_annotation(annotation)
    end

    uuid = annotation_uuid
    if annotation_ref && !Annotation.find(uuid).present?
      puts `MIGRATION: point #{point.id} has annotation_ref but no corresponding annotation`
      return
    end

    annotation.index_elasticsearch
  end

  def annotation_uuid
    Point.determine_uuid(annotation_ref)
  end

  def self.determine_uuid(value)
    utf_encoded = value.encode('UTF-8') + '=='.encode('UTF-8')
    # Returns the Base64-decoded version of str
    # https://ruby-doc.org/stdlib-2.4.0/libdoc/base64/rdoc/Base64.html#method-i-urlsafe_decode64
    b64_decoded = Base64.urlsafe_decode64(utf_encoded)
    # unpack decoded with uuid format
    # https://apidock.com/ruby/String/unpack
    b64_decoded.unpack('H8H4H4H4H12').join('-')
    # TO-DO: check for flake id, error handling, tests
  end

  def determine_url_safe_id(value)
    hex_string = UUID.validate(value) && value.split("-").join
    data = Binascii.a2b_hex(hex_string)
    b64_encoded = Base64.urlsafe_encode64(data)
    b64_encoded[0...-2]
  end

  def build_target_selectors
    target_selectors = []
    target_selectors << {
                            "type"=>"RangeSelector",
                            "endOffset"=>nil,
                            "startOffset"=>nil,
                            "endContainer"=>nil,
                            "startContainer"=>nil
                          }
    target_selectors << { "end"=>nil, "type"=>"TextPositionSelector", "start"=>nil }
    exact = quote_text
    document_text = document.text
    prefix = document_text[quote_start - 31...quote_start]
    suffix = document_text[quote_end...quote_end + 31]
    target_selectors << {'type'=>'TextQuoteSelector', 'exact'=>exact, 'prefix'=>prefix, 'suffix'=>suffix}
    target_selectors
  end

  def build_annotation
    document_id = retrieve_annotation_document_id
    {
      userid: 'acct:' + user.username + '@' + ENV['WEB_HOST'],
      groupid: '__world__',
      tags: [] << self.case.title,
      shared: true,
      target_uri: determine_target_uri(self),
      target_uri_normalized: determine_target_uri_normalized(self),
      target_selectors: build_target_selectors,
      references: [],
      extra: { "serviceId" => service.id.to_s, "documentId" => document_id.to_s },
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
    puts `MIGRATION ERROR for #{point.id} at annotation creation: #{e.record.errors}`
  end

  def retrieve_annotation_document_id
    target_uri = determine_target_uri(self)
    annotations_at_target = Annotation.where(target_uri: target_uri)

    if annotations_at_target.present?
      annotations_at_target.pluck(:document_id).uniq[0]
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
      ref = determine_url_safe_id(annotation.id)
      update!(annotation_ref: ref)
    end
    annotation.reload
    annotation
  rescue ActiveRecord::RecordInvalid => e
    puts `MIGRATION ERROR for #{point.id} at link annotation: #{e.record.errors}`
  end

  def index_annotation_to_es
    client = Elasticsearch::Client.new url: 'http://elasticsearch:9200', index: 'hypothesis', log: true
    Annotation.__elasticsearch__.client = client
    Annotation.__elasticsearch__.client.index index: 'hypothesis', type: 'annotation', id: determine_url_safe_id(id), body: build_annotation
  end

  private

  def determine_target_uri(point)
    path = Rails.application.routes.url_helpers.service_url(point.service, only_path: true)
    # this is really bad but we need to do it for the migration
    if Rails.env == 'development'
      'http://' + ENV['WEB_HOST'] + ':' + ENV['WEB_PORT'] + path + '/annotate'
    else
      'https://' + ENV['WEB_HOST'] + path + '/annotate'
    end
  end

  def determine_target_uri_normalized(point)
    # this is really bad but we need to do it for the migration
    path = Rails.application.routes.url_helpers.service_url(point.service, only_path: true)
    if Rails.env == 'development'
      'httpx://' + ENV['WEB_HOST'] + ':' + ENV['WEB_PORT'] + path + '/annotate'
    else
      'httpx://' + ENV['WEB_HOST'] + path + '/annotate'
    end
  end
end
