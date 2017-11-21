class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable
  has_many :points

  after_create :send_welcome_mail

  def admin?
    self.admin
  end

  def curator?
    self.curator
  end

  def send_welcome_mail
    UserMailer.welcome(self).deliver_now
  end
end
