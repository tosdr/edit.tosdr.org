class Service < ApplicationRecord
  has_paper_trail
  has_many :points

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :url, presence: true

  attr_accessor :service_rating

  scope :with_points, -> { joins(:points).where.not(points: []).distinct }

  def points_by_topic(query)
    points.joins(:topic).where("topics.title ILIKE ?", "%#{query}%")
  end

  def self.search_by_name(query)
    Service.where("name ILIKE ?", "%#{query}%")
  end


  def service_rating
    @service_rating ||= service_rating_get
  end

  private

  def service_rating_get
    total_ratings = points.map { |p| p.rating }
    num_bad = 0
    num_blocker = 0
    num_good = 0
    points.each do |p|
      if (p.rating < 2)
        num_blocker++
      elsif (p.rating < 5)
        num_bad++
      elsif (p.rating > 5)
        num_good++
      end
    end
    balance = num_good - num_bad - 3 * num_blocker
    if (balance < -10)
      return "E"
    elsif (num_blocker > 0)
      return "D"
    elsif (balance < -4)
      return "C"
    elsif (num_bad > 0)
      return "B"
    else
      return "A"
    end
  end

end
