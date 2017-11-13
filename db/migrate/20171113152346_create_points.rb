class CreatePoints < ActiveRecord::Migration[5.1]
  def change
    create_table :points do |t|
      t.references :user, foreign_key: true
      t.integer :rank
      t.string :title
      t.string :source
      t.string :status
      t.text :analysis
      t.integer :rating
      t.boolean :featured, default: false

      t.timestamps
    end
  end
end
