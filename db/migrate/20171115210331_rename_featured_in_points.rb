class RenameFeaturedInPoints < ActiveRecord::Migration[5.1]
  def change
    rename_column :points, :featured, :is_featured
  end
end
