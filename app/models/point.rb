# frozen_string_literal: true

class Point < ApplicationRecord
  has_paper_trail
  belongs_to :user, optional: true
  belongs_to :topic, optional: true
  belongs_to :document, optional: true

  belongs_to :service
  belongs_to :case

  has_many :point_comments, dependent: :destroy

  validates :title, presence: true
  validates :title, length: { in: 5..140 }
  validates :source, presence: true
  validates :status, inclusion: { in: ['approved', 'pending', 'declined', 'changes-requested', 'draft', 'approved-not-found', 'pending-not-found'], allow_nil: false }
  validates :case_id, presence: true

  def self.search_points_by_multiple(query)
    Point.joins(:service).where('services.name ILIKE ? or points.status ILIKE ? OR points.title ILIKE ?', "%#{query}%", "%#{query}%", "%#{query}%")
  end
end
