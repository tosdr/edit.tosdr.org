class Topic < ApplicationRecord
  has_many :points

  validates :title, presence: true, uniqueness: true
  validates :subtitle, presence: true
  validates :description, presence: true

  def self.search_by_topic_title(query)
    Topic.all.select { |t| t.title.downcase == query.downcase }
  end
end
