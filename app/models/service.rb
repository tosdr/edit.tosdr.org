class Service < ApplicationRecord
  has_many :points
  belongs_to :tosdr_rating

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :url, presence: true
end
