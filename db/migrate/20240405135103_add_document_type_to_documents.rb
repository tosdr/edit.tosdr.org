class AddDocumentTypeToDocuments < ActiveRecord::Migration[5.2]
  def change
    add_reference :documents, :document_type, foreign_key: true
  end
end