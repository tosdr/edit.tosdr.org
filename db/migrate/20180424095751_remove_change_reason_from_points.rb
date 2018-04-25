class RemoveChangeReasonFromPoints < ActiveRecord::Migration[5.1]
  def change
    remove_column :points, :change_reason, :text
  end
end
