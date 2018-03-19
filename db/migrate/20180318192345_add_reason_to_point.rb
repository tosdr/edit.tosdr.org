class AddReasonToPoint < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :reason, :text
  end
end
