class AddFieldsToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :keywords, :string
    add_column :services, :related, :string
    add_column :services, :slug, :string
  end
end
