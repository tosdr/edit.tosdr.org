Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  if Rails.env.production?
    config.environment = 'production'
  else
    config.environment = 'development'
  end

  config.traces_sample_rate = 0.1
end