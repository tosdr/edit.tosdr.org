require 'rails_helper'

BASE_OTA_URL = 'http://api.opentermsarchive.org/v1'.freeze

def stub_get_service_request(resource, query_string)
  response = {
    "results": [
      {
        "collection": "pga",
        "service": {
          "id": "facebook",
          "name": "Facebook",
          "url": "http://173.173.173.173/api/v1/service/facebook",
          "termsTypes": [ "Terms of Service", "Privacy Policy", "Developer Terms", "Trackers Policy", "Data Processor Agreement"]
        }
      },
      {
        "collection": "contrib",
        "service": {
          "id": "facebook",
          "name": "Facebook",
          "url": "http://162.162.162.162/api/v1/service/facebook",
          "termsTypes": [ "Terms of Service", "Privacy Policy"]
        }
      }
    ],
    "failures": []
  }

  response = response.to_json

  url = "#{BASE_OTA_URL}/#{resource}#{query_string}"
  stub_request(:get, url).
    with(
      headers: {
      'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent'=>'Ruby'
      }
    ).
    to_return(body: response)
  uri = URI.parse(url)
  req = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")
  Net::HTTP.start(uri.host, uri.port) do |http|
    http.request(req)
  end
end
