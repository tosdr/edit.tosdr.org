class PointComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :point
end
