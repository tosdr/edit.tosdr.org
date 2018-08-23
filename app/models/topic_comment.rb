class TopicComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :topic
end
