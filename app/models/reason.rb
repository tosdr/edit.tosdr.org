class Reason < ApplicationRecord
  belongs_to :user
  belongs_to :point

  validates :content, presence: true

  after_create :send_mail

  def send_mail
    UserMailer.status_update(self).deliver_now
  end

end
