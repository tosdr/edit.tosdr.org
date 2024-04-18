class CreateDocumentTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :document_types do |t|
      t.string :name
      t.references :document, foreign_key: true
      t.timestamps
    end
  end
end
