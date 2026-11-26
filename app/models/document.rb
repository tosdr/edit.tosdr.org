# frozen_string_literal: true

# app/models/document.rb
class Document < ApplicationRecord
  has_paper_trail

  belongs_to :service
  belongs_to :user, optional: true
  belongs_to :document_type, optional: true

  has_many :points
  has_many :document_comments, dependent: :destroy

  # What #reconcile_points! did to the points after the text changed: quotes no longer in the
  # text, quotes moved to a new location, and previously missing quotes found again.
  PointReconciliation = Struct.new(:missing, :relocated, :found_again, keyword_init: true)

  # Set by #reconcile_points!; nil when this instance's text hasn't been saved with a change.
  attr_reader :point_reconciliation

  # text_version identifies the exact text: a SHA-256 hex digest of the raw stored text, so the
  # same text always has the same version (including text that reverts to an earlier one).
  # Docbot compares it against the version it last processed to skip unchanged documents.
  before_save :set_text_version, if: :will_save_change_to_text?

  # Every update that changes the text re-checks the points against it, inside the same
  # transaction, so no path that writes new text (crawl, edit, console) can skip it. Not on
  # create: a document being created has no points yet.
  after_update :reconcile_points!, if: :saved_change_to_text?

  # Soft-delete: deprecated documents have status 'deleted' and are hidden from every
  # read path. The predicate is NULL-safe (most documents have a NULL status).
  # The column must stay table-qualified: when this scope lands in a JOIN's ON clause
  # (e.g. a Ransack search across points and services) a bare `status` is ambiguous.
  default_scope { where("#{quoted_table_name}.status IS DISTINCT FROM 'deleted'") }

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

  # Deprecate any still-active document whose service is already deprecated. Mirrors
  # Point.deprecate_orphans!: covers documents orphaned by a service marked 'deleted'
  # directly in the DB, or that predate the deprecation cascade. Without this, an active
  # document hanging off a hidden service has a nil `service` (the association applies
  # Service's default scope) and 500s every view that reads document.service. Idempotent.
  #
  # The active set comes from the default scope (`status IS DISTINCT FROM 'deleted'`),
  # which is NULL-safe -- a plain `where.not(status: 'deleted')` would silently drop the
  # legacy NULL-status rows that make up most documents. update_all (not the #deprecate!
  # cascade) hides the rows in bulk without tripping validations; run Point.deprecate_orphans!
  # afterwards to hide the points hanging off the documents this deprecates.
  def self.deprecate_orphans!
    deleted_services = Service.unscoped.where(status: 'deleted').select(:id)
    orphan_ids = where(service_id: deleted_services).pluck(:id)
    return if orphan_ids.empty?

    with_deleted.where(id: orphan_ids).update_all(status: 'deleted')
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

  # Bring every tracked point in line with the current text. For each point:
  #   - quote still at its stored location: nothing to do;
  #   - quote elsewhere (exactly, or ignoring tags/whitespace/case -- see QuoteLocator): move
  #     quote_start/quote_end there and set quote_text to the raw text at that spot;
  #   - quote nowhere: demote approved/pending to its *-not-found status.
  # A *-not-found point whose quote is found returns to approved/pending. Otherwise the status is
  # left alone. Runs after every update that changes the text (crawl, edit -- see the
  # after_update above), so the annotate view only has to read. Idempotent. Points without
  # offsets (those created from the Hypothesis sidebar) aren't tracked: see
  # docs/hypothesis-sync/README.md. Returns, and keeps, a PointReconciliation.
  def reconcile_points!
    raw_text = text.to_s
    locator = QuoteLocator.new(raw_text)
    missing = []
    relocated = []
    found_again = []

    # find_each queries fresh rows without caching them on the association, so a `points`
    # loaded before the text changed can't go stale, and none is left cached afterwards.
    points.find_each do |point|
      next unless point.quote_locatable?

      location = locator.locate(point.quote_text, stored_start: point.quote_start)
      if location.nil?
        missing << point
        point.mark_quote_not_found!
        next
      end

      moved = point.quote_start != location.begin || point.quote_end != location.end
      was_missing = Point::QUOTE_NOT_FOUND_STATUSES.value?(point.status)
      next unless point.mark_quote_found!(location, raw_text[location])

      relocated << point if moved
      found_again << point if was_missing
    end

    Rails.logger.info(
      "Document #{id}: reconciled points with new text (#{missing.length} missing, " \
      "#{relocated.length} relocated, #{found_again.length} found again)"
    )
    @point_reconciliation = PointReconciliation.new(missing: missing, relocated: relocated,
                                                    found_again: found_again)
  end

  def formatted_last_crawl_date
    last_crawl_date&.strftime('%Y-%m-%d %H:%M:%S')
  end

  # Split the text into plain and highlighted snippets for the annotate view. Read-only: a point
  # is highlighted when the text at its stored offsets is its quote, and #reconcile_points!
  # keeps those offsets current whenever the text changes.
  def snippets
    text_to_scan = text.to_s
    quotes = points.select do |p|
      p.quote_locatable? && p.quote_start && p.quote_end &&
        text_to_scan[p.quote_start...p.quote_end] == p.quote_text
    end

    snippets = []
    cursor = 0

    quotes.sort_by(&:quote_start).each do |q|
      # Skip a quote overlapping the previous highlight. One starting right at the cursor (at
      # position 0, or immediately after the previous quote) is still highlighted.
      next if q.quote_start < cursor

      snippets << { text: text_to_scan[cursor...q.quote_start] } if q.quote_start > cursor
      snippets << { pointId: q.id, text: text_to_scan[q.quote_start...q.quote_end], title: q.title }
      cursor = q.quote_end
    end

    snippets << { text: text_to_scan[cursor..] }
  end

  private

  def set_text_version
    self.text_version = text.nil? ? nil : Digest::SHA256.hexdigest(text)
  end
end
