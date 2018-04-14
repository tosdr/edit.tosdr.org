class Point < ApplicationRecord
 has_paper_trail
 belongs_to :user, optional: true
 belongs_to :service
 has_many :reasons, dependent: :destroy
 belongs_to :topic

 validates :title, presence: true
 validates :title, length: { in: 5..140 }
 validates :source, presence: true
 validates :status, inclusion: { in: ["approved", "pending", "declined", "disputed", "draft"], allow_nil: false }
 validates :analysis, presence: true
 validates :rating, presence: true
 validates :rating, numericality: true

def self.search_points_by_multiple(query)
  Point.joins(:service).where("services.name ILIKE ? or points.status ILIKE ?", "%#{query}%", "%#{query}%")
end

def self.search_points_by_topic(query)
  Point.joins(:topic).where("topics.title ILIKE ?", "%#{query}%")
end

# VOTE CONTROLLER ! TODO
  # def has_voted(point)
  #   Vote.where(point_id: point.id, user_id: current_user.id)
  # end
end
