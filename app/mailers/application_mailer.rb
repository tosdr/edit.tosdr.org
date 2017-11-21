class ApplicationMailer < ActionMailer::Base
  default from: 'automatic-email@tosdr.org'
  layout 'mailer'
end
