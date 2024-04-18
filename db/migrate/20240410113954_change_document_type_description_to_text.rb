class ChangeDocumentTypeDescriptionToText < ActiveRecord::Migration[5.2]
  def change
    change_column :document_types, :description, :text
  end
end