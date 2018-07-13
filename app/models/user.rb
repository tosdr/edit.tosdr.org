class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  has_many :points
  validate :password_complexity, on: [:create, :update]

  after_create :send_welcome_mail

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    return if password.blank? || password =~ /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,128}$/

    errors.add :password, 'Complexity requirement not met. Lenght should be 8-128 character and include: 1 Upper case, 1 lower case, 1 digit and 1 special char'
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
    if Comment.where user_id: self.id
      c = Comment.where user_id: self.id
      c.update_all user_id: 1
    end
  end
end
