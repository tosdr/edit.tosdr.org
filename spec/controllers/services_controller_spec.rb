require 'rails_helper'

# spec/controllers/services_controller_spec.rb
describe ServicesController do
  login_user

  context 'OTA API' do
    describe '#index' do
      it 'retrieves services from the OTA API' do
      end
    end

    describe '#show' do
      # example response object:
      # {
      #   "results": [
      #     {
      #       "collection": "pga",
      #       "service": {
      #         "id": "facebook",
      #         "name": "Facebook",
      #         "url": "http://173.173.173.173/api/v1/service/facebook",
      #         "termsTypes": [ "Terms of Service", "Privacy Policy", "Developer Terms", "Trackers Policy", "Data Processor Agreement"]
      #       }
      #     },
      #     {
      #       "collection": "contrib",
      #       "service": {
      #         "id": "facebook",
      #         "name": "Facebook",
      #         "url": "http://162.162.162.162/api/v1/service/facebook",
      #         "termsTypes": [ "Terms of Service", "Privacy Policy"]
      #       }
      #     }
      #   ],
      #   "failures": []
      # }
      it 'retrieves the service from the OTA API using the service name' do
        # get /service/search?name=facebook
      end

      context 'duplicates' do
        it 'prioritizes service defined in the pga collection' do
          # example response object:
          #   {
          #       "collection": "pga",
          #       "service": {
          #         "id": "facebook",
          #         "name": "Facebook",
          #         "url": "http://173.173.173.173/api/v1/service/facebook",
          #         "termsTypes": [ "Terms of Service", "Privacy Policy", "Developer Terms", "Trackers Policy", "Data Processor Agreement"]
          #       }
          #   }
        end

        it 'retrieves first result if service not defined the pga collection' do
          # example response object
          #     {
          #       "collection": "contrib",
          #       "service": {
          #         "id": "facebook",
          #         "name": "Facebook",
          #         "url": "http://162.162.162.162/api/v1/service/facebook",
          #         "termsTypes": [ "Terms of Service", "Privacy Policy"]
          #       }
          #     }
        end
      end

      context 'service does not exist' do
        it 'returns HTTP 404' do
        end
      end
    end

    describe '#create' do
      it 'creates a service to be stored in the tosdr collection' do
      end
    end

    describe '#update' do
      it 'updates the service in the tosdr collection' do
      end
    end

    describe '#destroy' do
      it '?' do
        # Do collections allow for DELETE requests?
      end
    end

    context 'OTA API failure' do
      it 'returns error message for collection' do
        # example response object
        # {
        #   "results": [
        #     …
        #   ],
        #   "failures": [
        #     {
        #       "collection": "demo",
        #       "message": "The API service encountered an internal error while processing the request.",
        #     },
        #     {
        #       "collection": "contrib",
        #       "message": "The API is currently unreachable.",
        #     }
        #   ]
        # }
      end
    end
  end
end
