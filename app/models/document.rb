# frozen_string_literal: true

# app/models/document.rb
class Document < ApplicationRecord
  has_paper_trail

  belongs_to :service
  belongs_to :user, optional: true

  has_many :points
  has_many :document_comments, dependent: :destroy

  validates :name, presence: true
  validates :url, presence: true
  validates :service_id, presence: true

  validate :custom_uniqueness_check

  def self.search_by_document_name(query)
    Document.joins(:service).where('services.name ILIKE ? or documents.name ILIKE ? or documents.url ILIKE?', "%#{query}%", "%#{query}%", "%#{query}%")
  end

  def custom_uniqueness_check
    doc = Document.where(url: url, xpath: xpath, status: nil)

    return unless doc.any? && (doc.first.id != id)

    go_to_doc = Rails.application.routes.url_helpers.document_url(doc.first.id)
    errors.add(:url, "A document for this URL already exists! Inspect it here: #{go_to_doc}")
  end

  def fetch_ota_text
    versions = %w[pga-versions contrib-versions]
    service_name = service.name
    service_name = service_name.strip
    service_name = service_name.gsub(/\s/, '%20')

    # first: check for document in pga
    version_name = versions[0]
    document_ota_url = generate_ota_url(version_name, service_name)
    document_markdown = HTTParty.get(document_ota_url)

    # second: check for document in contrib
    if document_markdown.code == 404
      version_name = versions[1]
      document_ota_url = generate_ota_url(version_name, service_name)
      document_markdown = HTTParty.get(document_ota_url)
    end

    # early return if document not stored in ota github
    return if document_markdown.code == 404

    document_html = Kramdown::Document.new(document_markdown).to_html

    # compare text for **possible** language differences
    # old_text_snippets = retrieve_snippets(document_html)
    self.text = document_html
    self.ota_sourced = true
    self.url = document_ota_url
    self.crawler_server = nil
    save
  end

  def generate_ota_url(version, service)
    document_name = name
    document_name = document_name.strip
    document_name = document_name.gsub(/\s/, '%20')

    "https://raw.githubusercontent.com/OpenTermsArchive/#{version}/main/#{service}/#{document_name}.md"
  end

  def snippets
    retrieve_snippets(text)
  end

  def retrieve_snippets(text_given)
    text_to_scan = text_given ? text_given : ''

    quotes = []
    snippets = []
    points_with_quote_text_to_restore_in_doc = []

    points.each do |p|
      next if p.status == 'declined'
      next if p.quote_text.nil? || (p.quote_start.nil? && p.quote_end.nil?)

      quote_exists_in_text = !text_to_scan.index(p.quote_text).nil?
      if quote_exists_in_text
        quote_start = text_to_scan.index(p.quote_text)
        quote_start_changed = p.quote_start != quote_start
        quote_end_changed = p.quote_end != p.quote_start + p.quote_text.length

        quote_ok = !quote_start_changed && !quote_end_changed
        quote_ok ? quotes << p : points_with_quote_text_to_restore_in_doc << p
      end
    end

    cursor = 0

    quotes.sort! do |x, y|
      puts 'comparing ' + x.quote_start.to_s + ' to ' + y.quote_start.to_s
      x.quote_start - y.quote_start
    end

    quotes.each do |q|
      puts 'quote to snippet ' + q.quote_start.to_s + ' -> ' + q.quote_end.to_s + ' ..' + cursor.to_s
      if q.quote_start > cursor
        puts 'unquoted ' + cursor.to_s + ' -> ' + q.quote_start.to_s
        snippets.push({
                        text: text_to_scan[cursor, q.quote_start - cursor]
                      })
        puts 'quoted ' + q.quote_start.to_s + ' -> ' + q.quote_end.to_s
        snippets.push({
                        pointId: q.id,
                        text: text_to_scan[q.quote_start, q.quote_end - q.quote_start],
                        title: q.title
                      })
        puts 'cursor to ' + q.quote_end.to_s
        cursor = q.quote_end
      end
    end

    puts 'final snippet ' + cursor.to_s + ' -> ' + text_to_scan.length.to_s

    snippets.push({
                    text: text_to_scan[cursor, text_to_scan.length - cursor]
                  })

    {
      snippets: snippets,
      points_needing_restoration: points_with_quote_text_to_restore_in_doc
    }
  end
end