# frozen_string_literal: true

# app/models/service.rb
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

  def calculate_service_rating
    perform_calculation
  end

  def points_ordered_status_class
    service_points_hash = (points.group_by { |point| point.status }).sort_by { |key| key }.reverse.to_h

    service_points_hash.each_value do |points|
      sort_service_points(points)
    end
  end

  def pending_points
    !points.nil? ? points.where(status: "pending") : []
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

  def approved_points
    points.select { |p| p.status == 'approved' && !p.case.nil? }
  end

  def perform_calculation
    counts = determine_counts
    balance = determine_balance(counts)
    calculate_grade(counts, balance)
  end

  def determine_counts
    total_ratings = approved_points.map { |p| p.case.classification }
    counts = Hash.new 0
    total_ratings.each { |rating| counts[rating] += 1 }
    counts
  end

  def determine_balance(counts)
    num_bad = counts['bad']
    num_blocker = counts['blocker']
    num_good = counts['good']

    num_good - num_bad - (num_blocker * 3)
  end

  def calculate_grade(counts, balance)
    if (counts['blocker'] + counts['bad'] + counts['good']).zero?
      'N/A'
    elsif balance <= -10 || counts['blocker'] > counts['good']
      'E'
    elsif counts['blocker'] >= 3 || counts['bad'] > counts['good']
      'D'
    elsif balance < 5
      'C'
    elsif counts['bad'].positive?
      'B'
    else
      'A'
    end
  end

  private

  def strip_input_fields
    attributes.each do |key, value|
      self[key] = value.strip if value.respond_to?('strip')
    end
  end
end
