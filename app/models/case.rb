class Case < ApplicationRecord
  has_many :points
  belongs_to :topic

  has_many :case_comments, dependent: :destroy

  def self.search_by_multiple(query)
    Case.where("title ILIKE ? or description ILIKE ?", "%#{query}%", "%#{query}%")
  end

  def determine_pointbox
    "point-" + classification
  end
end
