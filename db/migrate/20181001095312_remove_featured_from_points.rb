class RemoveFeaturedFromPoints < ActiveRecord::Migration[5.1]
  def change
    remove_column :points, :is_featured, :boolean
  end
end
