class Topic < ApplicationRecord
  has_many :points

  validates :title, presence: true, uniqueness: true
  validates :subtitle, presence: true
  validates :description, presence: true
end
