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

  def commented(author, point, commenter, commentText)
    @authorName = author.username || 'user ' + author.id.to_s
    @commenterName = commenter.username || commenter.id.to_s
    @title = 'User ' + @commenterName + ' commented on your point ' + point.id.to_s
    @pointUrl = 'https://edit.tosdr.org/points/' + point.id.to_s
    @commentText = commentText
    mail(to: author.email, subject: @title)
  end

  def reviewed(author, point, reviewer, verdict, commentText)
    @authorName = author.username || 'user ' + author.id.to_s
    @reviewerName = reviewer.username || reviewer.id.to_s
    verdictVerb = (verdict == 'changes-requested' ? 'requested you change' : verdict)
    @title = 'User ' + @reviewerName + ' ' + verdictVerb + ' your point ' + point.id.to_s
    @pointUrl = 'https://edit.tosdr.org/points/' + point.id.to_s
    @verdict = verdict
    @commentText = commentText
    mail(to: author.email, subject: @title)
  end
end
