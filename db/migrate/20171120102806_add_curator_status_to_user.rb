class AddCuratorStatusToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :curator, :boolean, default: false
  end
end
