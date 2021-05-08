# config/initializers/carrierwave.rb

CarrierWave.configure do |config|
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: ENV["S3_ACCESS_KEY"],
    aws_secret_access_key: ENV["S3_SECRET_KEY"],
    host: ENV["S3_HOST"],
    path_style: true,
    endpoint: ENV["S3_ENDPOINT"]
  }

  config.storage = :fog


  config.cache_dir = "#{Rails.root}/tmp/uploads"                  # To let CarrierWave work on heroku

  config.fog_directory    = ENV["S3_BUCKET"]
  config.fog_public     = false
end
