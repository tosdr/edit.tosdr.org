class AddDocBotToCases < ActiveRecord::Migration[5.2]
  def change
	add_column :cases, :docbot_regex, :string
  end
end
