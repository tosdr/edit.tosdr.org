class AddLastCrawlDateToDocuments < ActiveRecord::Migration[6.0]
  def change
    add_column :documents, :last_crawl_date, :datetime
  end
end
