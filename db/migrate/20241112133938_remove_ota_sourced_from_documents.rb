class RemoveOtaSourcedFromDocuments < ActiveRecord::Migration[6.0]
  def change
    remove_column :documents, :ota_sourced, :boolean
  end
end
