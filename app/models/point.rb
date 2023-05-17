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
    quote_start = document.text.index(quoteText)
    quote_end = quote_start + quoteText.length
    self.quoteStart = quote_start
    self.quoteEnd = quote_end
    save
  end

  def self.retrieve_annotation(id)
    retrieve_by_annotation_uuid(id)
  end

  # uuid - d8084a2c-c98b-11ed-bfb9-5341372e7080 - what's stored in h's annotation table
  # url-safe string from uuid (computed by h) - 2AhKLMmLEe2_uVNBNy5wgA - what we're sent from client
  def self.retrieve_by_annotation_uuid(id = nil)
    id ||= annotation_ref
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

  def self.determine_uuid(value)
    utf_encoded = value.encode('UTF-8') + '=='.encode('UTF-8')
    # Returns the Base64-decoded version of str
    # https://ruby-doc.org/stdlib-2.4.0/libdoc/base64/rdoc/Base64.html#method-i-urlsafe_decode64
    b64_decoded = Base64.urlsafe_decode64(utf_encoded)
    # unpack decoded with uuid format
    # https://apidock.com/ruby/String/unpack
    hex_str = b64_decoded.unpack('H8H4H4H4H12').join('-')
    hex_str
    # TO-DO: check for flake id, error handling, tests
  end
end
