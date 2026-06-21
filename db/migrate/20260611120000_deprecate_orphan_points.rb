# frozen_string_literal: true

# One-time cleanup: deprecate any still-active point whose service or document is
# already marked 'deleted'. Restores the tree invariant (a visible point always has a
# visible service) for data that predates the deprecation cascade — e.g. services that
# were marked 'deleted' directly in the database before this feature existed.
#
# The same logic runs daily via config/initializers/scheduler.rb to catch future drift,
# so this migration only needs to handle the backlog at deploy time.
class DeprecateOrphanPoints < ActiveRecord::Migration[7.1]
  def up
    Point.deprecate_orphans!
  end

  def down
    # No-op: deprecated points cannot be reliably restored to their prior status.
  end
end
