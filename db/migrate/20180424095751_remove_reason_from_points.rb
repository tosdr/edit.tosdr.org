class RemoveReasonFromPoints < ActiveRecord::Migration[5.1]
  def change
    remove_column :points, :reason, :text
  end
end
