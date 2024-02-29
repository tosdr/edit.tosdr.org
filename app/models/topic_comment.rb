# frozen_string_literal: true

# app/models/topic_comment.rb
class TopicComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :topic
  belongs_to :user
  has_many :spams, as: :spammable
end
