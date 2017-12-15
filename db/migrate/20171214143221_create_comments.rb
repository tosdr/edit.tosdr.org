class CreateComments < ActiveRecord::Migration[5.1]
  def change
    create_table :comments do |t|
      t.references :point, foreign_key: true
      t.string :summary

      t.timestamps
    end
  end
end
