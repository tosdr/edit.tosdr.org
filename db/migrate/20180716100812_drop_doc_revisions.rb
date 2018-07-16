class DropDocRevisions < ActiveRecord::Migration[5.1]
  def up
    drop_table :doc_revisions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
