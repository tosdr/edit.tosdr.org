class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def welcome(user)
    @user = user

    # @greeting =

    mail(to: @user.email, subject: 'Welcome')
  end

  def status_update(reason)
    @user = reason.point.user

    @message = "The status of your analysis has been reviewed by a curator. Please log into ToS;DR to review changes to your analyses."

    mail(to: @user.email, subject: 'Status update')
  end
end
