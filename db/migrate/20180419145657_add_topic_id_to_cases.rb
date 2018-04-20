class AddTopicIdToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :topic_id, :integer
    add_index :cases, :topic_id
  end
end
