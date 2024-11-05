class DropReasons < ActiveRecord::Migration[6.0]
  def change
    drop_table :reasons
  end
end
