class RemoveDocumentFromDocumentTypes < ActiveRecord::Migration[5.2]
  def change
    remove_column :document_types, :document_id, :bigint
  end
end