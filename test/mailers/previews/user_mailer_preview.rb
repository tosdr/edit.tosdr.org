class UserMailerPreview < ActionMailer::Preview
  def status_update
    reason = Reason.first
    UserMailer.status_update(reason)
  end
end
