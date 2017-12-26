class AddWikipediaLinkToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :wikipedia, :string
  end
end
