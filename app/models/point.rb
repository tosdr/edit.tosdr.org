class Point < ApplicationRecord
 has_paper_trail
 belongs_to :user, optional: true
 belongs_to :topic, optional: true

 belongs_to :service
 belongs_to :case

 has_many :comments, dependent: :destroy

 validates :title, presence: true
 validates :title, length: { in: 5..140 }
 validates :source, presence: true
 validates :status, inclusion: { in: ["approved", "pending", "declined", "disputed", "draft"], allow_nil: false }
 validates :analysis, presence: true
 validates :case_id, presence: true

def self.search_points_by_multiple(query)
  Point.joins(:service).where("services.name ILIKE ? or points.status ILIKE ? OR points.title ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
end

def self.search_points_by_topic(query)
  Point.joins(:topic).where("topics.title ILIKE ?", "%#{query}%")
end

# def check_changed_attributes_for_service_rating_update
#   self.service_needs_rating_update = true if (self.changed_attributed.keys & %w[
#     rating
#     ]).any?
# end

end
