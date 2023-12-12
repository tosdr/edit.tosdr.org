class AddOtaSourcedToDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :documents, :ota_sourced, :boolean, default: false
  end
end