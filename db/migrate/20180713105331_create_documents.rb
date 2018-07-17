class CreateDocuments < ActiveRecord::Migration[5.1]
  def change
    create_table :documents do |t|
      t.string :name
      t.string :url
      t.string :xpath
      t.string :text

      t.timestamps
    end
  end
end
