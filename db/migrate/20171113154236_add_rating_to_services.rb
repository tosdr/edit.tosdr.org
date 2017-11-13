class AddRatingToServices < ActiveRecord::Migration[5.1]
  def change
    add_reference :services, :tosdr_rating, foreign_key: true
  end
end
