class Topic < ApplicationRecord
  has_many :points

  validates :title, presence: true, uniqueness: true
  validates :subtitle, presence: true
  validates :description, presence: true

  def self.search_by_topic_title(query)
    Topic.where("title ILIKE ?", "%#{query}%")
  end

  def self.search_by_topic_service(query)
    Topic.joins(:point).where("points.name ILIKE ?", "%#{query}%")
  end

end
