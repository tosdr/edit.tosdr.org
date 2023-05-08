class AddHKeyToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :h_key, :string
  end
end
