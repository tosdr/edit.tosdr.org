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

  def hard_delete
    self.points.update_all user_id: 1 # change to anonymous account id
    if PointComment.where user_id: self.id
      c = PointComment.where user_id: self.id
      c.update_all user_id: 1
    end
  end

  # def active_for_authentication?
  #   super && !deactivated
  # end
end
