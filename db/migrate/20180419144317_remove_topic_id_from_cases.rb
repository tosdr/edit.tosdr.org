class RemoveTopicIdFromCases < ActiveRecord::Migration[5.1]
  def change
    remove_column :cases, :topic_id, :integer
  end
end
