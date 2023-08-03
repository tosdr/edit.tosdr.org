# frozen_string_literal: true

# app/services/ota/retrieve_service.rb
class Ota::RetrieveService
  BASE_OTA_URL = 'http://api.opentermsarchive.org/v1'

  def initialize(service_name:, terms_type:, collection:)
    @service_name = service_name
    @terms_type = terms_type
    @collection = collection
  end

  def service
    query_string = build_query
    url = "#{BASE_OTA_URL}/services#{query_string}"
    uri = URI.parse(url)
    req = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
  end

  private

  def build_query
    query_string = "?name=#{@service_name}"
    query_string += "&termsType=#{@terms_type}" if @terms_type.present?
    query_string += "&collection=#{@collection}" if @collection.present?
    query_string
  end
end
