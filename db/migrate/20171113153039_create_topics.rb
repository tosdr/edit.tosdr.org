class CreateTopics < ActiveRecord::Migration[5.1]
  def change
    create_table :topics do |t|
      t.string :title
      t.string :subtitle
      t.string :description

      t.timestamps
    end
  end
end
