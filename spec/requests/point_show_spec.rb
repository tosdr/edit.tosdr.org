require 'rails_helper'

RSpec.describe 'Point page', type: :request do
  before { host! 'example.com' }

  it "shows the point's quote without the retired Change excerpt workflow" do
    author = create(:user_confirmed, admin: false, curator: false)
    document = create(:document, text: 'Intro. We collect your data and keep it.')
    point = create(:point, user: author, service: document.service, document: document,
                           status: 'approved-not-found', quote_text: 'We collect your data')
    sign_in author

    get point_path(point)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('We collect your data')
    expect(response.body).not_to include('Change excerpt')
    expect(response.body).not_to include('point_id=')
  end
end
