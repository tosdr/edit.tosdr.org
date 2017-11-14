class DropTosdrRatingsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :tosdr_ratings
  end
end
