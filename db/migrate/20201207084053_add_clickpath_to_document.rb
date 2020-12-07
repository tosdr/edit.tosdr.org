class AddClickpathToDocument < ActiveRecord::Migration[5.1]
  def change
    add_column :documents, :clickpath, :string
  end
end
