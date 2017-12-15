class CreateCases < ActiveRecord::Migration[5.1]
  def change
    create_table :cases do |t|
      t.string :classification
      t.integer :score
      t.string :title
      t.text :description
      t.references :topic, foreign_key: true

      t.timestamps
    end
  end
end
