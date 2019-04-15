class AddUserRefToDocuments < ActiveRecord::Migration[5.1]
  def change
    add_reference :documents, :user, foreign_key: true
  end
end
