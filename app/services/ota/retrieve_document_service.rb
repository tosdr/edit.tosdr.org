# frozen_string_literal: true

# app/services/ota/retrieve_document_service.rb
class Ota::RetrieveDocumentService
  def initialize(ota_service_link:)
    @ota_service_link = ota_service_link
  end

  def document
    uri = URI.parse(@ota_service_link)
    req = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
  end
end
