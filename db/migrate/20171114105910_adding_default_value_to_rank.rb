class AddingDefaultValueToRank < ActiveRecord::Migration[5.1]
  def change
    change_column :points, :rank, :integer, default: 0
  end
end
