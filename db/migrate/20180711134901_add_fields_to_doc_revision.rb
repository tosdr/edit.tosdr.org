class AddFieldsToDocRevision < ActiveRecord::Migration[5.1]
  def change
    add_column :doc_revisions, :text, :string
    add_column :doc_revisions, :url, :string
    add_column :doc_revisions, :xpath, :string
  end
end
