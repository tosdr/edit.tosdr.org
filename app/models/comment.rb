class Comment < ApplicationRecord
  # belongs_to :user
  belongs_to :point

  validates :summary, presence: true
end
