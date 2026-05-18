require 'rails_helper'

RSpec.describe ApplicationService do
  it 'uses HTTPS for the Open Terms Archive API base URL' do
    expect(described_class::BASE_OTA_URL).to start_with('https://')
  end
end
