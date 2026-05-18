# app/services/application_service.rb
class ApplicationService
  BASE_OTA_URL = 'https://api.opentermsarchive.org/v1'.freeze
  def self.call(*args)
    new(*args).call
  end
end
