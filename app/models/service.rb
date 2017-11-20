class Service < ApplicationRecord
  has_many :points

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :url, presence: true

  def points_by_topic(query)
    points.joins(:topic).where("topics.title ILIKE ?", "%#{query}%")
  end

  def self.search_by_name(query)
    Service.where("name ILIKE ?", "%#{query}%")
  end

  def service_ratings
    total_ratings = points.map { |p| p.rating }
    avg = (total_ratings.sum.to_f) / (total_ratings.size.to_f)
    unless avg.nan?
      case avg.round
      when 9..10
        "A"
      when 7..8
        "B"
      when 5..6
        "C"
      when 3..4
        "D"
      when 0..2
        "F"
      else
        "N/A"
      end
    else
      "N/A"
    end
  end

end
