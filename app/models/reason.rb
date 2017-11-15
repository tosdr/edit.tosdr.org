class Reason < ApplicationRecord
  belongs_to :user
  belongs_to :point

  validates :content, presence: true
end
