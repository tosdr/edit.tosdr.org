class RenameModelVersionOnPoints < ActiveRecord::Migration[5.2]
  def change
    rename_column :points, :model_version, :docbot_version
  end
end