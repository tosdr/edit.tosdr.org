class AddRatingToService < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :rating, :string
  end
end
