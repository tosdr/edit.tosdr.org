class AddServiceRefToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_reference :documents, :service, foreign_key: true
  end
end
