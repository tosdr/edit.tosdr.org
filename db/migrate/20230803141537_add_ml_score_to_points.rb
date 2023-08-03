class AddMlScoreToPoints < ActiveRecord::Migration[5.2]
  def change
    add_column :points, :ml_score, :integer
  end
end
