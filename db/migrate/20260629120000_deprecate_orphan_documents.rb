# frozen_string_literal: true

# One-time cleanup: deprecate any still-active document whose service is already marked
# 'deleted', then re-run the point orphan sweep to hide the points hanging off those
# documents. Restores the tree invariant (a visible document always has a visible service)
# for data that predates the document deprecation cascade -- e.g. a service marked 'deleted'
# directly in the database, whose documents were never cascaded. Such orphan documents have
# a nil `service` and 500 the documents index/show/edit pages.
#
# The same logic runs daily via config/initializers/scheduler.rb to catch future drift, so
# this migration only needs to handle the backlog at deploy time.
class DeprecateOrphanDocuments < ActiveRecord::Migration[7.1]
  def up
    Document.deprecate_orphans!
    Point.deprecate_orphans!
  end

  def down
    # No-op: deprecated records cannot be reliably restored to their prior status.
  end
end
