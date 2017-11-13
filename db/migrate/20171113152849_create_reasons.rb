class CreateReasons < ActiveRecord::Migration[5.1]
  def change
    create_table :reasons do |t|
      t.text :reason
      t.references :user, foreign_key: true
      t.references :point, foreign_key: true

      t.timestamps
    end
  end
end
