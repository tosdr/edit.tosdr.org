class AddStatusToDocumentTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :document_types, :status, :string
  end
end