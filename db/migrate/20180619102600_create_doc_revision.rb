class CreateDocRevision < ActiveRecord::Migration[5.1]
  def change
    create_table :doc_revisions do |t|
      t.string :name
      t.string :revision
      t.references :service, foreign_key: true
    end
  end
end
