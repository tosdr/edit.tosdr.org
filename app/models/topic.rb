class Topic < ApplicationRecord
  has_paper_trail
  has_many :points
  has_many :cases

  has_many :topic_comments, dependent: :destroy

  validates :title, presence: true, uniqueness: true
  validates :subtitle, presence: true
  validates :description, presence: true

  def self.search_by_topic_title(query)
    Topic.where("title ILIKE ?", "%#{query}%")
  end

  def self.search_by_topic_service(query)
    Topic.joins(:point).where("points.name ILIKE ?", "%#{query}%")
  end

  def self.topic_use_frequency
    Topic.where.not(id: 53).includes(:cases).joins(cases: :points).group(:id).order('COUNT(points.id) DESC')
  end

  def case_use_frequency
    self.cases.left_joins(:points).group(:id).order('COUNT(points.id) DESC')
  end
end
