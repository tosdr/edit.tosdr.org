class ServiceComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :service
  belongs_to :user
  has_many :spams, as: :spammable
end
