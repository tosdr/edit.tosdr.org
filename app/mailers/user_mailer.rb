class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def welcome(user)
    @user = user

    mail(to: @user.email, subject: 'Welcome to ToS;DR!')
  end

  def status_update(reason)
    @user = reason.point.user

    mail(to: @user.email, subject: 'Status update from ToS;DR')
  end
end
