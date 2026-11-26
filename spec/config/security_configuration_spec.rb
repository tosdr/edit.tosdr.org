require 'rails_helper'

RSpec.describe 'security configuration' do
  it 'filters bearer credentials from logs' do
    expect(Rails.application.config.filter_parameters).to include(:h_key, :'H-Key', :token)
  end

  # The navbar's log-out links are plain GET links (see shared/_navbar.html.erb).
  it 'signs out via GET' do
    expect(Devise.sign_out_via).to eq(:get)
  end
end
