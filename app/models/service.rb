class Service < ApplicationRecord
  has_many :points

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :url, presence: true

  def service_ratings
    total_ratings = points.map { |p| p.rating }
    avg = (total_ratings.sum.to_f) / (total_ratings.size.to_f)
    avg.round
  end
end
