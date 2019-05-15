# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :confirmable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  has_many :points
  has_many :documents
  has_many :services

  validate :password_validation, if: :password

  after_create :send_welcome_mail

  def password_validation
    unless password =~ /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/
      errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit'
    end
  end

  def admin?
    admin
  end

  def curator?
    curator
  end

  def send_welcome_mail
    UserMailer.welcome(self).deliver_now
  end

  def hard_delete
    self.update username: username + "[USER LEFT]"
    self.deactivated = true
  end
  
  def active_for_authentication?
    super && !self.deactivated?
  end

end
