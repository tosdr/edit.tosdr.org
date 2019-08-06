class RemoveTopicFromPoints < ActiveRecord::Migration[5.1]
  def change
    remove_column :points, :topic_id, :bigint
  end
end
