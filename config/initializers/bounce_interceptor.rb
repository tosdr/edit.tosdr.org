# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActionMailer::Base.register_interceptor(BounceInterceptor)
end
