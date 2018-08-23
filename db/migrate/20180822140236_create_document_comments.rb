class CreateDocumentComments < ActiveRecord::Migration[5.1]
  def change
    create_table :document_comments do |t|
      t.string :summary
      t.references :document, foreign_key: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
