class AddTosbackToPoint < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :quoteDoc, :string
    add_column :points, :quoteRev, :string
    add_column :points, :quoteStart, :int
    add_column :points, :quoteEnd, :int
    rename_column :points, :quote, :quoteText
  end
end
