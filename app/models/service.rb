require "#{Rails.root}/lib/tosbackdoc.rb"
require "json"

puts 'loaded?'
puts TOSBackDoc

class Service < ApplicationRecord
  has_paper_trail

  belongs_to :user, optional: true

  has_many :points
  has_many :documents

  has_many :service_comments, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :url, presence: true
  validates :url, uniqueness: true

  before_validation :strip_input_fields

  def self.search_by_name(query)
    Service.where("name ILIKE ?", "%#{query}%")
  end

  def calculate_service_rating
    perform_calculation
  end

  def getMainPageLinks
    mainPageUrl = 'https://' + self.url.split(',')[0]
    @tbdoc = TOSBackDoc.new({
      url: mainPageUrl,
      xpath: nil
    })
    puts 'milog scraping ' + mainPageUrl
    @tbdoc.scraperaw
    puts 'milog scraped ' + mainPageUrl
    t = @tbdoc.newdata
    # t = '<script type="text/javascript"> var settings_js_version = "/s2477.js", locale = "en_US"; </script> <script type="text/javascript" src="/lib/l119.js"></script> <script type="text/javascript" src="/locale/en_US/duckduckgo14.js"></script> <script type="text/javascript" src="/util/u506.js"></script> <script type="text/javascript" src="/d2885.js"></script> <script type="text/javascript"> DDG.page = new DDG.Pages.Home(); </script> <div class="site-wrapper site-wrapper--home js-site-wrapper"> <div class="header-wrap--home js-header-wrap"> <div class="header--aside js-header-aside"><a class="header__button--menu js-side-menu-open" href="#">⇶</a><div class="header--aside__item showcase header__label"><span class="header__clickable js-hl-button" data-type="showcase"><span class="js-popout-trig" aria-haspopup="true" aria-label="Check out the list of things that we\'ve also made." role="button" aria-pressed="false"><span id="wedonttrack">Privacy, simplified.</span></span><span class="popout-trig js-popout"><span class="js-popout-link js-showcase-popout ddgsi ddgsi-down" aria-hidden="true" data-type="showcase"></span><div class="modal modal--popout modal--popout--bottom-left modal--popout--sm js-popout-main" data-type="showcase"><div class="modal__box"><div class="modal__body"><nav aria-labelledby="wedonttrack"><section class="showcase__dropdown-top"><ul aria-label="Here are some things that we made that you might like."><li class="fix showcase__dropdown__list"><a href="/app" class="eighteen js-hl-item" aria-hidden="true" data-type="showcase" data-id="app"><div class="woman-icon"></div></a><a href="/app" class="text-left showcase__link eighty js-hl-item" data-type="showcase" data-id="app"><h1 class="showcase__heading">Get Our App &amp; Extension</h1>'
    # t = 'a <a href="asdf">jolly</a> link and <a href="qwer">another</a> one'
    # t = 'a <a href="asdf">jolly</a> link'
    # t = "this is some string"
    m = t.scan(/<a.*?>(.*?)<\/a.*?>/)
    # m = t.scan(/<a.*>(.*)<\/a.*>/)
    json = JSON.generate(m)
    puts 'milog m ' + json[1, json.length - 2]
    json[1, json.length - 2]
  end

  def points_ordered_status_class
    service_points_hash = (points.group_by { |point| point.status }).sort_by { |key| key }.reverse.to_h

    service_points_hash.each_value do |points|
      sort_service_points(points)
    end
  end

  def pending_points
    !self.points.nil? ? self.points.where(status: "pending") : []
  end

  def sort_service_points(points)
    classifications = ['good', 'neutral', 'bad', 'blocker']

    points.sort! do |a, b|
      a_class = a.case&.classification
      b_class = b.case&.classification

      if !classifications.include?(a.case&.classification) || !classifications.include?(b.case&.classification)
        0
      elsif a_class == b_class
        0
      elsif a_class == 'good'
        -1
      elsif b_class == 'good'
        1
      elsif a_class == 'neutral'
        -1
      elsif b_class == 'neutral'
        1
      elsif a_class == 'bad'
        -1
      elsif b_class == 'bad'
        1
      end
    end
  end

  private

  def strip_input_fields
    self.attributes.each do |key, value|
      self[key] = value.strip if value.respond_to?("strip")
    end
  end

  def perform_calculation
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
