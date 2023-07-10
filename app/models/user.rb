# frozen_string_literal: true
require 'securerandom'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :confirmable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  has_many :points
  has_many :documents
  has_many :services

  attr_accessor :skip_on_sign_out

  validate :password_validation, if: :password
  validate :username_validation, if: :username, unless: :skip_on_sign_out

  HTTP_URL_REGEX = /\b(?:(?:mailto:\S+|(?:https?|ftp|file):\/\/)?(?:\w+\.)+[a-z]{2,6})\b/
  URL_REGEX = /\b(?:(?:\w+\.)+[a-z]{2,6})\b/
  PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/
  USERNAME_REGEX = /\A[\w\.]+\z/

  def password_validation
    password_valid = password =~ PASSWORD_REGEX
    errors.add :password, 'Must include at least one lowercase letter, one uppercase letter, and one digit' unless password_valid
  end

  def normalize_username
    username.present? ? username.gsub(/[^a-zA-Z0-9\_\.]/, '') : 'anonymous'
  end

  def username_validation
    errors.add(:username, 'Username cannot contain links, and must have only letters, numbers, periods, and underscores') if (username.match HTTP_URL_REGEX) || (username.match URL_REGEX) || !(username.match USERNAME_REGEX)
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

  def hard_delete
    points.update_all user_id: 1 # change to anonymous account id
    if PointComment.where user_id: id
      c = PointComment.where user_id: id
      c.update_all user_id: 1
    end
  end

  def after_database_authentication
    self.skip_on_sign_out = true
    self.h_key = SecureRandom.hex(13) unless self.h_key
    save!
  end
end
