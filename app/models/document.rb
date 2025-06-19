# frozen_string_literal: true

# app/models/document.rb
class Document < ApplicationRecord
  has_paper_trail

  belongs_to :service
  belongs_to :user, optional: true
  belongs_to :document_type, optional: true

  has_many :points
  has_many :document_comments, dependent: :destroy

  validates :name, presence: true
  validates :service_id, presence: true
  validates :text, presence: true
  validates :url, presence: true
  validates :selector, presence: true

  validate :location_uniqueness_check

  def location_uniqueness_check
    doc = Document.where(url: url, selector: selector, status: nil)

    return unless doc.any? && (doc.first.id != id)

    go_to_doc = Rails.application.routes.url_helpers.document_url(doc.first.id)
    errors.add(:url, "A document for this URL already exists! Inspect it here: #{go_to_doc}")
  end

  def snippets
    cache_key = "doc:#{id}:snippets:v1"
  
    if text.length > 50_000
      cached = Rails.cache.read(cache_key)
      SnippetCacheRefreshJob.perform_later(id) unless cached
      cached || []
    else
      Rails.cache.fetch(cache_key, expires_in: 12.hours) do
        retrieve_snippets(text)
      end
    end
  end

  def handle_missing_points
    text_to_scan = text
    points_no_longer_in_text = []

    points.each do |p|
      next if p.status == 'declined'
      next if p.quote_text.blank? || (p.quote_start.blank? && p.quote_end.blank?)
      next if p.annotation_ref.nil?

      quote_exists_in_text = !text_to_scan.index(p.quote_text).nil?
      points_no_longer_in_text << p unless quote_exists_in_text

      p.status = p.status == 'approved' ? 'approved-not-found' : 'pending-not-found'
      p.save
    end

    points_no_longer_in_text
  end

  def formatted_last_crawl_date
    last_crawl_date&.strftime('%Y-%m-%d %H:%M:%S')
  end

  def retrieve_snippets(text_given)
    SnippetRetriever.new(text: text_given, points: points).call
  end 
end
