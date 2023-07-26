# app/services/ota/retrieve_service.rb
class Ota::RetrieveService
  BASE_OTA_URL = 'http://api.opentermsarchive.org/v1'.freeze

  def initialize(service_name:, terms_type:)
    @service_name = service_name
    @terms_type = terms_type
  end

  def call(*args)
    new(*args).service
  end

  def service
    query_string = "?name=#{@service_name}"
    query_string = "#{query_string}&termsType=#{@terms_type}" if @terms_type.present?
    url = "#{BASE_OTA_URL}/services#{query_string}"
    uri = URI.parse(url)
    req = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
  end
end
