class RenameModelVersionOnDocbotRecords < ActiveRecord::Migration[5.2]
  def change
    rename_column :docbot_records, :model_version, :docbot_version
  end
end