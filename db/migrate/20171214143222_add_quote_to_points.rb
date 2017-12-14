class AddQuoteToPoints < ActiveRecord::Migration[5.1]
  def change
    add_column :points, :quote, :string
  end
end
