class ServiceComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :service
  has_many :spams, as: :spammable
end
