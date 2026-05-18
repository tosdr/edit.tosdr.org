require 'rails_helper'

RSpec.describe 'Services quote', type: :request do
  it 'rejects documents that do not belong to the service being quoted' do
    host! 'example.com'
    user = FactoryBot.create(:user_confirmed)
    service = FactoryBot.create(:service)
    other_service = FactoryBot.create(:service)
    other_document = FactoryBot.create(:document, service: other_service, text: 'Other service legal text')
    case_ref = FactoryBot.create(:case)
    sign_in user

    params = {
      quoteCaseId: case_ref.id,
      document_id: other_document.id,
      quote_start: 0,
      quote_end: 5
    }

    expect { post annotate_path(service), params: params }.not_to change(Point, :count)
    expect(response).to have_http_status(:not_found)
  end
end
