class Point < ApplicationRecord
 has_paper_trail
 belongs_to :user, optional: true
 belongs_to :service
 belongs_to :topic
 belongs_to :case

 has_many :comments, dependent: :destroy

 validates :title, presence: true
 validates :title, length: { in: 5..140 }
 validates :source, presence: true
 validates :status, inclusion: { in: ["approved", "pending", "declined", "disputed", "draft"], allow_nil: false }
 validates :analysis, presence: true
 validates :rating, presence: true
 validates :rating, numericality: true
 validates :case_id, presence: true

 # before_save :check_changed_attributes_for_service_rating_update
 # after_update :create_comment

def self.search_points_by_multiple(query)
  Point.joins(:service).where("services.name ILIKE ? or points.status ILIKE ? OR points.title ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
end

def self.search_points_by_topic(query)
  Point.joins(:topic).where("topics.title ILIKE ?", "%#{query}%")
end

def rating_for_table
  pointbox = if self.rating.between?(7, 10)
    "point-good"
  elsif self.rating.between?(4,6)
    "point-neutral"
  elsif self.rating.between?(2,3)
    "point-bad"
  elsif self.rating.between?(0,2)
    "point-blocker"
  end
end

# def check_changed_attributes_for_service_rating_update
#   self.service_needs_rating_update = true if (self.changed_attributed.keys & %w[
#     rating
#     ]).any?
# end

# def
end
