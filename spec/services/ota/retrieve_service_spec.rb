require 'rails_helper'
require 'ota_helper'

# spec/services/ota/retrieve_service_spec.rb
describe Ota::RetrieveService do
  describe '#service' do
    it 'retrieves services from federated OTA API using service name' do
      stub_service_request('services')
      res = described_class.new(service_name: 'facebook', terms_type: '', collection: '').service
      expect(res.code).to eq('200')
      body = JSON.parse(res.body)
      expect(body['results'].length).to eq(2)
    end

    it 'retrieves service from federated OTA API using service name and collection' do
      stub_service_request('services', 'collection')
      res = described_class.new(service_name: 'facebook', terms_type: '', collection: 'pga').service
      expect(res.code).to eq('200')
      body = JSON.parse(res.body)
      expect(body['results'].length).to eq(1)
    end

    it 'retrieves services from federated OTA API using service name and terms type' do
      stub_service_request('services', 'terms')
      res = described_class.new(service_name: 'facebook', terms_type: 'cookies%20policy', collection: '').service
      expect(res.code).to eq('200')
      body = JSON.parse(res.body)
      expect(body['results'].length).to eq(1)
    end

    it 'returns empty array if no service found' do
      stub_service_not_found
      res = described_class.new(service_name: 'doesnotexist', terms_type: '', collection: '').service
      expect(res.code).to eq('200')
      body = JSON.parse(res.body)
      expect(body['results'].length).to eq(0)
    end
  end

  context 'error' do
    it 'returns an error message for the collection' do
      stub_error
      res = described_class.new(service_name: 'facebook', terms_type: '', collection: '').service
      expect(res.code).to eq('200')
      body = JSON.parse(res.body)
      expect(body['failures'].length).to eq(2)
    end
  end
end
