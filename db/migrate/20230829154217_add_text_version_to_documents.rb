class AddTextVersionToDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :documents, :text_version, :string
  end
end