class Point < ApplicationRecord
  belongs_to :user
  belongs_to :topic
  belongs_to :service
  has_one :reason

  validates :title, presence: true
  validates :title, length: { in: 5..140 }
  validates :source, presence: true
  validates :status, inclusion: { in: ["approved", "pending", "declined", "disputed"], allow_nil: false }
  validates :analysis, presence: true
  validates :rating, presence: true
  validates :rating, numericality: true

end
