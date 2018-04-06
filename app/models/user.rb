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

  def destroy
    # fix this, it isn't working
    update_attributes(email: "deactivated_account@tosdr.org", username: "Camille", deactivated: true) unless deactivated
  end

  def active_for_authentication?
    super && !deactivated
  end
end
