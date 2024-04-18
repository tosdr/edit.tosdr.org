class AddDescriptionToDocumentTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :document_types, :description, :string
  end
end
