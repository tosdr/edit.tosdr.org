class AddServiceIdToPoints < ActiveRecord::Migration[5.1]
  def change
    add_reference :points, :service, foreign_key: true
  end
end
