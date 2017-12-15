class AddOldIdToTopics < ActiveRecord::Migration[5.1]
  def change
    add_column :topics, :oldId, :string
  end
end
