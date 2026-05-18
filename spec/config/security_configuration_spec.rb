require 'rails_helper'

RSpec.describe 'security configuration' do
  it 'filters bearer credentials from logs' do
    expect(Rails.application.config.filter_parameters).to include(:h_key, :'H-Key', :token)
  end

  it 'requires DELETE for Devise sign out' do
    expect(Devise.sign_out_via).to eq(:delete)
  end
end
