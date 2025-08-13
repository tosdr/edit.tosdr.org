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

  def document_type_uniqueness_check
    doc = Document.where(document_type_id: document_type_id, service_id: service_id)

    return unless doc.any? && (doc.first.id != id)

    go_to_doc = Rails.application.routes.url_helpers.document_url(doc.first.id)
    errors.add(:document_type_id, "This document already exists for this service! Inspect it here: #{go_to_doc}")
  end

  def convert_xpath_to_css
    runner = NodeRunner.new(
      <<~JAVASCRIPT
        const xPathToCss = require('xpath-to-css')
        const convert = (xpath) => {
          const css = xPathToCss(xpath)
          return css;
        }
      JAVASCRIPT
    )
    runner.convert xpath
  end

  def validate_selector
    runner = NodeRunner.new(
      <<~JAVASCRIPT
        const xPathToCss = require('xpath-to-css')
        const convert = (selector) => {
          const css = xPathToCss(selector)
          return css;
        }
      JAVASCRIPT
    )
    runner.convert selector
  end

  def snippets
    retrieve_snippets(text)
  end

  def handle_missing_points
    text_to_scan = text
    points_no_longer_in_text = []

    points.each do |_point|
      next if p.status == 'declined'
      next if p.quote_text.nil? || (p.quote_start.nil? && p.quote_end.nil?)
      next if p.annotation_ref.nil?

      points_no_longer_in_text = []
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
    text_to_scan = text_given || ''

    quotes = []
    snippets = []
    points_with_quote_text_to_restore_in_doc = []
    points_no_longer_in_text = []

    points.each do |p|
      next if p.status == 'declined'
      next if p.quote_text.nil? || (p.quote_start.nil? && p.quote_end.nil?)

      quote_exists_in_text = !text_to_scan.index(p.quote_text).nil?
      points_no_longer_in_text << p unless quote_exists_in_text
      next unless quote_exists_in_text

      quote_start = text_to_scan.index(p.quote_text)
      quote_start_changed = p.quote_start != quote_start
      quote_end_changed = p.quote_end != p.quote_start + p.quote_text.length

      quote_ok = !quote_start_changed && !quote_end_changed
      quote_ok ? quotes << p : points_with_quote_text_to_restore_in_doc << p
    end

    if points_no_longer_in_text.length
      points_no_longer_in_text.each do |p|
        next if p.status == 'approved-not-found'

        p.status = p.status == 'approved' ? 'approved-not-found' : 'pending-not-found'
        p.save
      end
    end

    cursor = 0

    quotes.sort! do |x, y|
      puts 'comparing ' + x.quote_start.to_s + ' to ' + y.quote_start.to_s
      x.quote_start - y.quote_start
    end

    quotes.each do |q|
      puts 'quote to snippet ' + q.quote_start.to_s + ' -> ' + q.quote_end.to_s + ' ..' + cursor.to_s
      next unless q.quote_start > cursor

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
