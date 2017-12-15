class AddOldIdToPoints < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :oldId, :string
  end
end
