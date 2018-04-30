class RemovingCommentsFromPoints < ActiveRecord::Migration[5.1]
  def change
    remove_table :comments
  end
end
