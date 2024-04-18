class AddUserRefToDocumentTypes < ActiveRecord::Migration[5.2]
  def change
    add_reference :document_types, :user, foreign_key: true
  end
end