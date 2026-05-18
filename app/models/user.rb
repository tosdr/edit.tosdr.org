# frozen_string_literal: true

require 'securerandom'

# app/models/user.rb
class User < ApplicationRecord
  MINIMUM_APPROVED_POINTS = 0

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :confirmable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  has_many :points
  has_many :point_vetoes, dependent: :destroy
  has_many :documents
  has_many :services
  has_many :point_comments
  has_many :case_comments
  has_many :document_comments
  has_many :service_comments
  has_many :topic_comments

  def self.ransackable_attributes(auth_object = nil)
    %w[email username admin curator bot deactivated verified_contributor approved_points_count level created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  attr_accessor :skip_on_sign_out

  validate :password_validation, if: :password
  validate :username_validation, if: :username, unless: :skip_on_sign_out

  HTTP_URL_REGEX = %r{\b(?:(?:mailto:\S+|(?:https?|ftp|file)://)?(?:\w+\.)+[a-z]{2,6})\b}
  URL_REGEX = /\b(?:(?:\w+\.)+[a-z]{2,6})\b/
  PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/
  USERNAME_REGEX = /\A[\w.]+\z/

  def self.docbot_user
    username = ENV['DOCBOT_USER']
    find_by_username(username)
  end

  def self.level_for_approved_points(count)
    approved_points = [count.to_i, MINIMUM_APPROVED_POINTS].max
    Math.sqrt(approved_points).floor + 1
  end

  def self.backfill_missing_levels!
    missing_ids = where(level: nil).pluck(:id)
    return if missing_ids.empty?

    approved_counts = Point.where(user_id: missing_ids, status: 'approved').group(:user_id).count

    where(id: missing_ids).find_each do |user|
      approved_points_count = approved_counts.fetch(user.id, MINIMUM_APPROVED_POINTS)
      user.update_columns(
        approved_points_count: approved_points_count,
        level: level_for_approved_points(approved_points_count),
        updated_at: Time.current
      )
    end
  end

  def password_validation
    password_valid = password =~ PASSWORD_REGEX
    message = 'Must include at least one lowercase letter, one uppercase letter, and one digit'
    errors.add :password, message unless password_valid
  end

  def username_validation
    invalid = (username.match HTTP_URL_REGEX) || (username.match URL_REGEX) || !(username.match USERNAME_REGEX)
    message = 'Username cannot contain links, and must have only letters, numbers, periods, and underscores'
    errors.add :username, message if invalid
  end

  def normalize_username
    username.present? ? username.gsub(/[^a-zA-Z0-9_.]/, '') : 'anonymous'
  end

  def admin?
    admin
  end

  def curator?
    curator
  end

  def bot?
    bot
  end

  def verified_contributor?
    verified_contributor
  end

  def level_two?
    level.to_i >= 2
  end

  def refresh_level_from_points!
    approved_count = points.where(status: 'approved').count

    update_columns(
      approved_points_count: approved_count,
      level: self.class.level_for_approved_points(approved_count),
      updated_at: Time.current
    )
  end

  before_destroy :hard_delete

  def hard_delete
    anonymous_id = 1
    points.update_all user_id: anonymous_id
    documents.update_all user_id: anonymous_id
    services.update_all user_id: anonymous_id
    point_comments.update_all user_id: anonymous_id
    case_comments.update_all user_id: anonymous_id
    document_comments.update_all user_id: anonymous_id
    service_comments.update_all user_id: anonymous_id
    topic_comments.update_all user_id: anonymous_id
    DocumentType.where(user_id: id).update_all user_id: anonymous_id
  end

  def after_database_authentication
    self.skip_on_sign_out = true
    self.h_key = SecureRandom.hex(13) unless h_key
    save!
  end
end
