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

  def service_rating
    points = self.points
    classification_counts = service_point_classifications_count(points)
    balance = calculate_balance(classification_counts)
    balance
  end

  def service_point_classifications_count(points)
    approved_points = points.select { |p| p.status == 'approved' && !p.case.nil? }
    total_ratings = approved_points.map { |p| p.case.classification }
    counts = Hash.new 0
    total_ratings.each { |rating| counts[rating] += 1 }
    counts
    # returns {"neutral"=>1, "good"=>9, "bad"=>5}
  end

  def calculate_balance(counts)
    num_bad = counts['bad']
    num_blocker = counts['blocker']
    num_good = counts['good']

    balance = num_good - num_bad - 3 * num_blocker
    balance

    if (num_blocker + num_bad + num_good == 0)
      return "N/A"
    elsif (balance < -10)
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
