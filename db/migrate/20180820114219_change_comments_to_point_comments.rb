class ChangeCommentsToPointComments < ActiveRecord::Migration[5.1]
  def self.up
    rename_table :comments, :point_comments
  end

  def self.down
    rename_table :point_comments, :comments
  end
end
