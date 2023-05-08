class CreateHKeys < ActiveRecord::Migration[5.2]
  def change
    create_table :h_keys do |t|
      t.references :user, foreign_key: true
      t.string :secret

      t.timestamps
    end
  end
end
