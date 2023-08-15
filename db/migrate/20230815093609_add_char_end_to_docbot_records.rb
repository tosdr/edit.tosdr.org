class AddCharEndToDocbotRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :docbot_records, :char_end, :integer
  end
end