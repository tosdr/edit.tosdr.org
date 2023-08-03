require 'rails_helper'
require 'ota_helper'

# spec/models/service_spec.rb
describe Service do
  context 'OTA' do
    before :each do
      @service = FactoryBot.create(:service, name: 'facebook')
    end

    describe '#ota_service' do
      it 'returns the matching service from the OTA API' do
        stub_service_request('services', 'collection')
        res = @service.ota_service
        res = res['service']
        expect(res).to_not be_nil
      end

      it 'prioritizes services from pga' do
        stub_service_request('services', 'collection')
        res = @service.ota_service
        expect(res['collection']).to eq('pga')
      end

      it 'prioritizes the first available service if no pga service' do
        stub_service_request('services', 'no_pga')
        res = @service.ota_service(false)
        expect(res['collection']).to eq('demo')
      end

      it 'returns nil if there is no matching service' do
        service = FactoryBot.create(:service, name: 'doesnotexist')
        stub_service_not_found
        res = service.ota_service(false)
        expect(res).to be_nil
      end

      it 'returns nil if there is an error' do
        stub_error
        res = @service.ota_service(false)
        expect(res).to be_nil
      end
    end

    describe '#ota_service_link' do
      it 'returns the link to the collection metadata api for the service' do
        stub_service_request('services', 'collection')
        res = @service.ota_service
        res = res['service']['url']
        expect(res).to eq("http://173.173.173.173/api/v1/service/facebook")
      end

      it 'returns nil if the service is not retrieved' do
        stub_error
        res = @service.ota_service(false)
        expect(res).to be_nil
      end
    end

    describe '#ota_documents' do
      it 'returns an array of available documents' do
        url = 'http://173.173.173.173/api/v1/service/facebook'
        stub_documents_request(url)
        res = @service.ota_documents(url)
        expect(res.length).to eq(2)
      end

      it 'filters the documents if terms type is specified' do
        url = 'http://173.173.173.173/api/v1/service/facebook'
        stub_documents_request(url)
        terms_type = 'Terms of Service'
        res = @service.ota_documents(url, terms_type)
        expect(res[0]['type']).to eq(terms_type)
      end
    end
  end
end
