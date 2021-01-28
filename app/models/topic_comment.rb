class TopicComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :topic
  has_many :spams, as: :spammable
end
