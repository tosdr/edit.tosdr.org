class UserMailerPreview < ActionMailer::Preview
  def welcome
    user = User.first
    UserMailer.welcome(user)
  end

  def status_update
    reason = Reason.first
    UserMailer.status_update(reason)
  end
end
