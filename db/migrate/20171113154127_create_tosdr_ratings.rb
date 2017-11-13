class CreateTosdrRatings < ActiveRecord::Migration[5.1]
  def change
    create_table :tosdr_ratings do |t|
      t.integer :class_rating

      t.timestamps
    end
  end
end
