class RenameXpathOnDocuments < ActiveRecord::Migration[5.2]
  def change
    rename_column :documents, :xpath, :selector
  end
end