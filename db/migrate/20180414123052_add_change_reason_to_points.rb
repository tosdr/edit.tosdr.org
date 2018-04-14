class AddChangeReasonToPoints < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :change_reason, :text
  end
end
