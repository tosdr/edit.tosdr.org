class Comment < ApplicationRecord
  validates :summary, presence: true
end
