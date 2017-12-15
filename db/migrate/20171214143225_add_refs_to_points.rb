class AddRefsToPoints < ActiveRecord::Migration[5.1]
  def change
    add_reference :points, :case, foreign_key: true
  end
end
