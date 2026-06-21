# frozen_string_literal: true

# Deprecate any still-active point whose service or document is already deprecated. 
# Covers orphans created before the service cascade handled document-less points, 
# and services/documents marked 'deleted' directly in the DB for whatever reason.

# Until this runs, orphaned points of deprecated services will cause 500s in Phoenix
# on certain pages that list points.

namespace :deprecation do
  desc 'Deprecate points whose service or document has already been deprecated (restores the tree invariant)'
  task backfill_orphans: :environment do
    before = Point.with_deleted.where(status: 'deleted').count
    Point.deprecate_orphans!
    after = Point.with_deleted.where(status: 'deleted').count
    puts "Deprecated #{after - before} orphaned point(s)."
  end
end
