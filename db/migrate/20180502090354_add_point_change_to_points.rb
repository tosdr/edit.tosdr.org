class AddPointChangeToPoints < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :point_change, :text
  end
end
