class PointComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :point
  belongs_to :user
  has_many :spams, as: :spammable
end
