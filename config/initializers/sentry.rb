Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.environment = Rails.env
  config.traces_sample_rate = 1.0
end