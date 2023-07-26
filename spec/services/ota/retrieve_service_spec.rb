require 'rails_helper'
require 'ota_helper'

# spec/services/ota/retrieve_service_spec.rb
describe Ota::RetrieveService do
  describe '#call' do
    it 'retrieves services from federated OTA API using service name' do
      stub_get_service_request('services', '?name=facebook')
      res = described_class.new(service_name: 'facebook', terms_type: '').service
      expect(res.code).to eq('200')
      body = JSON.parse(res.body)
      expect(body['results'].length).to eq(2)
    end
  end
end
