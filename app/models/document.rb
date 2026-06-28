# frozen_string_literal: true

# app/models/document.rb
class Document < ApplicationRecord
  has_paper_trail

  belongs_to :service
  belongs_to :user, optional: true
  belongs_to :document_type, optional: true

  has_many :points
  has_many :document_comments, dependent: :destroy

  # Soft-delete: deprecated documents have status 'deleted' and are hidden from every
  # read path. The predicate is NULL-safe (most documents have a NULL status).
  default_scope { where("status IS DISTINCT FROM 'deleted'") }

  # Escape hatch for console/admin use. A scope using `unscope(where: :status)` cannot
  # strip the raw-SQL default scope above, so bypass all scoping via `unscoped`.
  def self.with_deleted
    unscoped
  end

  # Content-field presence is enforced on create and whenever the field is actually being
  # changed, but a pre-existing record that leaves the field untouched is grandfathered --
  # so legacy rows with blank content stay editable/crawlable while we never write NEW
  # blanks. Structural FKs like service_id stay unconditionally required.
  validates :name, presence: true, unless: -> { persisted? && !name_changed? }
  validates :service_id, presence: true

  # Deprecate (soft-delete) this document and cascade to its points. Goes per-point
  # (not update_all) so PaperTrail versions and the point's user-level-refresh callbacks
  # fire. Both the points and the document itself are saved with validate: false: a
  # soft-delete only flips `status`, and a record's content validity (presence of text,
  # selector, etc.) must not gate hiding it -- legacy rows predate those validations.
  def deprecate!
    transaction do
      points.find_each(&:deprecate!)
      self.status = 'deleted'
      save!(validate: false)
    end
  end

  def self.ransackable_associations(auth_object = nil)
    ["service"]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name]
  end
  validates :text, presence: true, unless: -> { persisted? && !text_changed? }
  validates :url, presence: true, unless: -> { persisted? && !url_changed? }
  validates :selector, presence: true, unless: -> { persisted? && !selector_changed? }

  validate :location_uniqueness_check

  def location_uniqueness_check
    # Only meaningful when the location is actually (re)set; skipping it on unrelated
    # edits keeps legacy rows that share a blank url+selector editable.
    return unless new_record? || url_changed? || selector_changed?

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

  # Flag points whose quote no longer appears in the current document text, demoting
  # approved/pending points to their *-not-found status, and return the missing points.
  # Thin wrapper over #flag_points_missing_from -- the single source of truth shared with
  # #retrieve_snippets so the crawl (write) and annotation (read) paths can't diverge.
  def handle_missing_points
    flag_points_missing_from(text)
  end

  def formatted_last_crawl_date
    last_crawl_date&.strftime('%Y-%m-%d %H:%M:%S')
  end

  def retrieve_snippets(text_given)
    text_to_scan = text_given || ''

    # Shared detection: flag (and demote) every point whose quote is gone from the text.
    flag_points_missing_from(text_to_scan)

    quotes = []
    snippets = []
    points_with_quote_text_to_restore_in_doc = []

    points.each do |p|
      next unless p.quote_locatable?

      quote_start = text_to_scan.index(p.quote_text)
      next if quote_start.nil?

      quote_start_changed = p.quote_start != quote_start
      quote_end_changed = p.quote_end != p.quote_start + p.quote_text.length

      quote_ok = !quote_start_changed && !quote_end_changed
      quote_ok ? quotes << p : points_with_quote_text_to_restore_in_doc << p
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

  private

  # Single source of truth for missing-quote detection, shared by the crawl (write) path
  # (#handle_missing_points) and the annotation (read) path (#retrieve_snippets). Returns
  # every quote-locatable point whose quote_text no longer appears in `text_to_scan`, and
  # demotes the approved/pending ones to their *-not-found status as a side effect. The
  # flip is guarded per point (only the missing ones move) and idempotent, so re-running
  # over the same text makes no further changes and never touches still-present points.
  def flag_points_missing_from(text_to_scan)
    text_to_scan = text_to_scan.to_s
    missing = []

    points.each do |point|
      next unless point.quote_locatable?
      next if text_to_scan.include?(point.quote_text)

      missing << point
      point.mark_quote_not_found!
    end

    missing
  end
end
