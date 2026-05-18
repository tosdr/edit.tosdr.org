# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Service categories', type: :request do
  it 'allows curators to update multiple categories on a service' do
    host! 'example.com'
    curator = FactoryBot.create(:user_confirmed, admin: false, curator: true)
    service = FactoryBot.create(:service)
    sign_in curator

    patch service_path(service), params: {
      service: {
        name: service.name,
        url: service.url,
        wikipedia: service.wikipedia,
        categories: %w[ai file_sharing search_engine]
      }
    }

    expect(response).to redirect_to(service_path(service))
    expect(service.reload.categories).to contain_exactly('ai', 'file_sharing', 'search_engine')
  end

  it 'does not allow service owners without curator privileges to update categories' do
    host! 'example.com'
    owner = FactoryBot.create(:user_confirmed, admin: false, curator: false)
    service = FactoryBot.create(:service, user: owner, categories: ['ai'])
    sign_in owner

    patch service_path(service), params: {
      service: {
        name: service.name,
        url: service.url,
        wikipedia: service.wikipedia,
        categories: ['search_engine']
      }
    }

    expect(response).to redirect_to(service_path(service))
    expect(service.reload.categories).to eq(['ai'])
  end
end
