class ApplicationMailer < ActionMailer::Base
  default from: 'notifications@mail.tosdr.org'
  layout 'mailer'
end
