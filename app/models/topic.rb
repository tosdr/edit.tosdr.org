# frozen_string_literal: true

# app/models/topic.rb
class Topic < ApplicationRecord
  has_paper_trail
  has_many :points
  has_many :cases

  has_many :topic_comments, dependent: :destroy

  validates :title, presence: true, uniqueness: true
  validates :subtitle, presence: true
  validates :description, presence: true

  def self.search_by_topic_title(query)
    Topic.where("title ILIKE ?", "%#{query}%")
  end

  def self.topic_use_frequency
    Topic.where.not(id: 53).includes(:cases)
  end
end
