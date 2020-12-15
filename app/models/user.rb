# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :confirmable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  has_many :points
  has_many :documents
  has_many :services

  validate :password_validation, if: :password
  validate :username_validation, if: :username

  after_create :send_welcome_mail

  HTTP_URL_REGEX = /\b(?:(?:mailto:\S+|(?:https?|ftp|file):\/\/)?(?:\w+\.)+[a-z]{2,6})\b/
  URL_REGEX = /\b(?:(?:\w+\.)+[a-z]{2,6})\b/

  def password_validation
    unless password =~ /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/
      errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit'
    end
  end

  def username_validation
    errors.add(:username, "Your username cannot contain links") if (username.match HTTP_URL_REGEX) || (username.match URL_REGEX)
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

  def send_welcome_mail
    UserMailer.welcome(self).deliver_now
  end

  def hard_delete
    points.update_all user_id: 1 # change to anonymous account id
    if PointComment.where user_id: id
      c = PointComment.where user_id: id
      c.update_all user_id: 1
    end
  end

  # def active_for_authentication?
  #   super && !deactivated
  # end
end
