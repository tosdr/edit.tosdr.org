# frozen_string_literal: true
require 'fuzzystringmatch'

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
    jarow = FuzzyStringMatch::JaroWinkler.create(:native)
    match_threshold = 0.85

    quotes = []
    snippets = []
    points_with_quote_text_to_restore_in_doc = []
    points_no_longer_in_text = []

    normalized_text = text_to_scan.gsub(/\s+/, ' ')

    points.each do |p|
      next if p.status == 'declined'
      next if p.quote_text.nil? || (p.quote_start.nil? && p.quote_end.nil?)

      normalized_quote = p.quote_text.gsub(/\s+/, ' ')
      quote_start = normalized_text.index(normalized_quote)

      if quote_start.nil?
        # Fuzzy match fallback
        best_match_index = nil
        best_match_score = 0.0
        best_candidate = nil
        window_size = normalized_quote.length

        (0..(normalized_text.length - window_size)).each do |i|
          candidate = normalized_text[i, window_size]
          score = jarow.getDistance(normalized_quote, candidate)

          if score > best_match_score
            best_match_score = score
            best_match_index = i
            best_candidate = candidate
          end
        end

        if best_match_score >= match_threshold
          puts "🔍 Fuzzy match for Point ##{p.id} with score #{best_match_score.round(3)}"
          puts "→ Original: #{p.quote_text[0..80].inspect}"
          puts "→ Match:    #{best_candidate[0..80].inspect}"
          quote_start = best_match_index
        else
          puts "❌ No match for Point ##{p.id}"
          if p.status != 'approved-not-found' && p.status != 'pending-not-found'
            old_status = p.status
            p.status = old_status == 'approved' ? 'approved-not-found' : 'pending-not-found'
            p.save!
            puts "⚠️  Point ##{p.id} status changed from #{old_status} to #{p.status}"
          end
          points_no_longer_in_text << p
          next
        end
      end

      quote_end = quote_start + normalized_quote.length
      quote_start_changed = p.quote_start != quote_start
      quote_end_changed = p.quote_end != quote_end

      if p.status == 'approved-not-found'
        puts "✅ Point ##{p.id} (#{p.title}) restored. Status updated to 'approved'."
        p.status = 'approved'
        p.quote_start = quote_start
        p.quote_end = quote_end
        p.save!
        quotes << p
      elsif !quote_start_changed && !quote_end_changed
        quotes << p
      else
        puts "🛠️  Point ##{p.id} position mismatch. Old: #{p.quote_start}-#{p.quote_end}, New: #{quote_start}-#{quote_end}"
        points_with_quote_text_to_restore_in_doc << p
      end
    end

    cursor = 0
    quotes.sort_by!(&:quote_start)

    quotes.each do |q|
      next unless q.quote_start > cursor

      snippets << { text: text_to_scan[cursor, q.quote_start - cursor] }
      snippets << {
        pointId: q.id,
        text: text_to_scan[q.quote_start, q.quote_end - q.quote_start],
        title: q.title
      }
      cursor = q.quote_end
    end

    snippets << { text: text_to_scan[cursor, text_to_scan.length - cursor] }

    {
      snippets: snippets,
      points_needing_restoration: points_with_quote_text_to_restore_in_doc
    }
  end 
end
