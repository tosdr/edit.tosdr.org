class AddTopicToPoints < ActiveRecord::Migration[5.1]
  def change
    add_reference :points, :topic, foreign_key: true
  end
end
