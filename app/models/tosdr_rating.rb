class TosdrRating < ApplicationRecord
  has_many :services

  validates :class_rating, presence: true, numericality: true
end
