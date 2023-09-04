class AddMlScoreToDocbotRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :docbot_records, :ml_score, :decimal
  end
end