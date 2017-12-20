class AddDeactivateToUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :deactivate
    add_column :users, :deactivated, :boolean, default: false
  end
end
