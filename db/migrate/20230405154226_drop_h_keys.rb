class DropHKeys < ActiveRecord::Migration[5.2]
  def change
    drop_table :h_keys
  end
end
