require 'rails_helper'
require 'ota_helper'

# spec/models/service_spec.rb
describe Service do
  context 'OTA' do
    describe '#ota_service' do
      it 'returns the matching service from the OTA API' do
        service = FactoryBot.create(:service, name: 'facebook')
        stub_service_request('services', 'collection')
        res = service.ota_service
        res = res['service']
        expect(res).to_not be_nil
      end

      it 'prioritizes services from pga' do
        service = FactoryBot.create(:service, name: 'facebook')
        stub_service_request('services', 'collection')
        res = service.ota_service
        expect(res['collection']).to eq('pga')
      end

      it 'prioritizes the first available service if no pga service' do
        service = FactoryBot.create(:service, name: 'facebook')
        stub_service_request('services', 'no_pga')
        res = service.ota_service(false)
        expect(res['collection']).to eq('demo')
      end

      it 'returns nil if there is no matching service' do
        service = FactoryBot.create(:service, name: 'doesnotexist')
        stub_service_not_found
        res = service.ota_service(false)
        expect(res).to be_nil
      end

      it 'returns nil if there is an error' do
        service = FactoryBot.create(:service, name: 'facebook')
        stub_error
        res = service.ota_service(false)
        expect(res).to be_nil
      end
    end

    describe '#ota_service_link' do
      it 'returns the link to the collection metadata api for the service' do
        service = FactoryBot.create(:service, name: 'facebook')
        stub_service_request('services', 'collection')
        res = service.ota_service
        res = res['service']['url']
        expect(res).to eq("http://173.173.173.173/api/v1/service/facebook")
      end

      it 'returns nil if the service is not retrieved' do
        service = FactoryBot.create(:service, name: 'facebook')
        stub_error
        res = service.ota_service(false)
        expect(res).to be_nil
      end
    end
  end
end
