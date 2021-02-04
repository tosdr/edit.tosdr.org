class AddCrawlerServerToDocuments < ActiveRecord::Migration[5.2]
  def change
	add_column :documents, :crawler_server, :string
  end
end
