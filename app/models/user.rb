class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  has_many :points
  validate :password_validation

  after_create :send_welcome_mail

  def password_validation
    unless (password =~ /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit'
    end
  end

  def admin?
    self.admin
  end

  def curator?
    self.curator
  end

  def send_welcome_mail
    UserMailer.welcome(self).deliver_now
  end

  # def destroy
    # update_attributes(email: "deactivated_account@tosdr.org", username: "Camille", deactivated: true) unless deactivated
  # end

  # def active_for_authentication?
  #   super && !deactivated
  # end
end
