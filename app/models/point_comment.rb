class PointComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :point
  has_many :spams, as: :spammable
end
