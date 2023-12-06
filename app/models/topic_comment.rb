class TopicComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :topic
  belongs_to :user
  has_many :spams, as: :spammable
end
