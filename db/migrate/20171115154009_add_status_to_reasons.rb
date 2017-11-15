class AddStatusToReasons < ActiveRecord::Migration[5.1]
  def change
    add_column :reasons, :status, :string
  end
end
