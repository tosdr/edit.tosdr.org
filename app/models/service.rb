class Service < ApplicationRecord
  has_paper_trail
  has_many :points

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :url, presence: true


  scope :with_points_featured, -> { joins(:points).where("points.is_featured = true").distinct }

  def points_by_topic(query)
    points.joins(:topic).where("topics.title ILIKE ?", "%#{query}%")
  end

  def self.search_by_name(query)
    Service.where("name ILIKE ?", "%#{query}%")
  end


  def rating_for_view
    grade = if self.service_ratings == "A"
      "rating-a"
    elsif self.service_ratings == "B"
      "rating-b"
    elsif self.service_ratings == "C"
      "rating-c"
    elsif self.service_ratings == "D"
      "rating-d"
    elsif self.service_ratings == "E"
      "rating-e"
    else
      ""
    end
  end

  def service_ratings
    approved_points = points.select do |p|
      p.status == 'approved'
    end
    total_ratings = approved_points.map { |p| p.rating }
    num_bad = 0
    num_blocker = 0
    num_good = 0
    approved_points.each do |p|
      if (p.rating < 2)
        num_blocker += 1
      elsif (p.rating < 5)
        num_bad += 1
      elsif (p.rating > 5)
        num_good += 1
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
