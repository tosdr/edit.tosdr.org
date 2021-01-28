class AddBotToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :bot, :boolean, default: false
  end
end
