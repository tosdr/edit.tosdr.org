class AddServiceNeedsRatingUpdateToPoints < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :service_needs_rating_update, :boolean, default: false
  end
end
