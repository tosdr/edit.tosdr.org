class RemoveTosdrRatingIdFromServices < ActiveRecord::Migration[5.1]
  def change
    remove_column :services, :tosdr_rating_id
  end
end
