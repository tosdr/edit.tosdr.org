class RemoveRatingFromPoints < ActiveRecord::Migration[5.1]
  def change
    remove_column :points, :rating, :integer
  end
end
