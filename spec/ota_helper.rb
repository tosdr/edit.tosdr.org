require 'rails_helper'

BASE_OTA_URL = 'http://api.opentermsarchive.org/v1'.freeze

RESPONSE_NO_PGA = {
  "results": [
    {
      "collection": "demo",
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
        "termsTypes": [ "Terms of Service", "Privacy Policy", "Cookies Policy"]
      }
    }
  ],
  "failures": []
}

RESPONSE_NAME = {
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
        "termsTypes": [ "Terms of Service", "Privacy Policy", "Cookies Policy"]
      }
    }
  ],
  "failures": []
}

RESPONSE_TERMS_TYPE = {
  "results": [
    {
      "collection": "contrib",
      "service": {
        "id": "facebook",
        "name": "Facebook",
        "url": "http://162.162.162.162/api/v1/service/facebook",
        "termsTypes": [ "Terms of Service", "Privacy Policy", "Cookies Policy"]
      }
    }
  ],
  "failures": []
}

RESPONSE_PGA_COLLECTION = {
  "results": [
    {
      "collection": "pga",
      "service": {
        "id": "facebook",
        "name": "Facebook",
        "url": "http://173.173.173.173/api/v1/service/facebook",
        "termsTypes": [ "Terms of Service", "Privacy Policy", "Developer Terms", "Trackers Policy", "Data Processor Agreement"]
      }
    }
  ],
  "failures": []
}

RESPONSE_EMPTY = {
  "results": [],
  "failures": []
}

RESPONSE_FAILURE = {
  "results": [],
  "failures": [
    {
      "collection": "demo",
      "message": "The API service encountered an internal error while processing the request.",
    },
    {
      "collection": "contrib",
      "message": "The API is currently unreachable.",
    }
  ]
}

RESPONSE_DOCUMENTS = {
  "id": "service-1",
  "name": "Service/1",
  "terms": [
    {
      "type": "Terms of Service",
      "sourceDocuments": [
        {
          "location": "https://service1.com/tos-1",
          "executeClientScripts": false,
          "contentSelectors": "#main",
          "insignificantContentSelectors": ".returnToTop",
          "filters": ["cleanUrls"],
        },
        {
          "location": "https://service1.com/tos-2",
          "executeClientScripts": false,
          "contentSelectors": "#main",
          "insignificantContentSelectors": ".returnToTop",
          "filters": ["cleanUrls"],
        }
      ]  
    },
    {
      "type": "Privacy Policy",
      "sourceDocuments": [
        {
          "location": "https://service1.com/privacy-policy",
          "executeClientScripts": true,
          "contentSelectors": "body",
          "insignificantContentSelectors": ".returnToTop",
          "filters": ["cleanUrls"],
        }
      ]
    }
  ],
  "filters": "function cleanUrls(document) {…}"
}

def stub_base(url, response)
  response = response.to_json
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

def stub_documents_request(url)
  response = RESPONSE_DOCUMENTS
  stub_base(url, response)
end

def stub_service_request(resource, filter = nil)
  query_string = build_query(filter)
  response = build_response(filter)
  url = "#{BASE_OTA_URL}/#{resource}#{query_string}"
  stub_base(url, response)
end

def stub_service_not_found
  response = RESPONSE_EMPTY
  url = "#{BASE_OTA_URL}/services?name=doesnotexist"
  stub_base(url, response)
end

def stub_error
  response = RESPONSE_FAILURE
  url = "#{BASE_OTA_URL}/services?name=facebook"
  stub_base(url, response)
end

def build_response(filter)
  return RESPONSE_NAME unless filter

  case filter
  when 'terms'
    RESPONSE_TERMS_TYPE
  when 'collection'
    RESPONSE_PGA_COLLECTION
  when 'no_pga'
    RESPONSE_NO_PGA
  else
    RESPONSE_NAME
  end
end

def build_query(filter)
  query_string = '?name=facebook'
  return query_string unless filter || filter == 'no_pga'

  query_string += '&termsType=cookies%20policy' if filter == 'terms'
  query_string += '&collection=pga' if filter == 'collection'
  query_string
end
