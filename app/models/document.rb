class Document < ApplicationRecord
  has_paper_trail

  belongs_to :service

  validates :name, presence: true
  validates :url, presence: true, uniqueness: true
  validates :service_id, presence: true

  def self.search_by_document_name(query)
    Document.where("name ILIKE ?", "%#{query}%")
  end
end
