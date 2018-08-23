class CreateCaseComments < ActiveRecord::Migration[5.1]
  def change
    create_table :case_comments do |t|
      t.string :summary
      t.references :case, foreign_key: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
