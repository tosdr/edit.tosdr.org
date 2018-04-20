class RemoveTopicsFkFromCases < ActiveRecord::Migration[5.1]
  def change
    if foreign_key_exists?(:cases, :topics)
      remove_foreign_key :cases, :topics
    end
  end
end
