class Reason < ApplicationRecord
  belongs_to :user
  belongs_to :point

  validates :reason, presence: true
end
