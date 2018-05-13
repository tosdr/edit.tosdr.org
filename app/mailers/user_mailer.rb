class UserMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def welcome(user)
    @user = user

    @greeting = "You're now a confirmed contributor of Terms of Service; Didn't Read crowdreading tool.
 Please bear in mind that this version is a beta version that is still under development. You can follow the development on our github (https://github.com/tosdr/phoenix ).

 It means that things can change, a lot. Our privacy policy and terms of service are going to change, we will keep you updated.

      Happy contributing!"

    mail(to: @user.email, subject: 'Welcome')
  end

  def status_update(reason)
    @user = reason.point.user

    @message = "The status of your analysis has been reviewed by a curator. Please log into ToS;DR to review changes to your analyses."

    mail(to: @user.email, subject: 'Status update')
  end
end
