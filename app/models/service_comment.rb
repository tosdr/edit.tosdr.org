class ServiceComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :service
end
