# frozen_string_literal: true

# Restore the tree invariant (a visible child always has a visible ancestor) for data that
# drifted out of the deprecation cascade -- e.g. a service or document marked 'deleted'
# directly in the DB, or rows that predate the cascade. Deprecates any still-active document
# whose service is deprecated, then any still-active point whose service or document is.
#
# Until this runs, orphaned documents/points of deprecated services cause 500s in Phoenix on
# pages that list or render them (the hidden ancestor makes document.service / point.service nil).

namespace :deprecation do
  desc 'Deprecate documents and points whose service/document has already been deprecated (restores the tree invariant)'
  task backfill_orphans: :environment do
    docs_before = Document.with_deleted.where(status: 'deleted').count
    points_before = Point.with_deleted.where(status: 'deleted').count

    # Documents first: deprecating an orphan document turns its points into orphans, which
    # the points pass below then catches.
    Document.deprecate_orphans!
    Point.deprecate_orphans!

    docs_after = Document.with_deleted.where(status: 'deleted').count
    points_after = Point.with_deleted.where(status: 'deleted').count
    puts "Deprecated #{docs_after - docs_before} orphaned document(s)."
    puts "Deprecated #{points_after - points_before} orphaned point(s)."
  end
end
