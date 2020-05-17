class AddUserAndCleanedToSpams < ActiveRecord::Migration[5.1]
  def change
    add_column :spams, :flagged_by_admin_or_curator, :boolean, default: false
    add_column :spams, :cleaned, :boolean, default: false
  end
end
