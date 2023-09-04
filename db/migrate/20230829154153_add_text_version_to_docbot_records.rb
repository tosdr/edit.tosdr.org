class AddTextVersionToDocbotRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :docbot_records, :text_version, :string
  end
end