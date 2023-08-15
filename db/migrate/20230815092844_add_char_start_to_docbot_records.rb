class AddCharStartToDocbotRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :docbot_records, :char_start, :integer
  end
end