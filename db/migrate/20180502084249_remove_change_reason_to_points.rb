class RemoveChangeReasonToPoints < ActiveRecord::Migration[5.1]
  def change
    remove_column :points, :change_reason
  end
end
