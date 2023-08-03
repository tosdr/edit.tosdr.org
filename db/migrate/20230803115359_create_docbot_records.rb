class CreateDocbotRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :docbot_records do |t|
      t.string :model_version
      t.references :document, foreign_key: true
      t.references :case, foreign_key: true
      t.timestamps
    end
  end
end