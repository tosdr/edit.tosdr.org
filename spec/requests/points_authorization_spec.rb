require 'rails_helper'

# Regression coverage: PointPolicy#show? was `true`, exposing non-approved points to
# logged-out visitors.
RSpec.describe 'Point authorization', type: :request do
  # The base user factory is admin + curator, so ordinary contributors opt out explicitly.
  let(:author) { create(:user_confirmed, admin: false, curator: false) }
  let(:curator) { create(:user_confirmed, admin: false) }

  before { host! 'example.com' }

  describe 'GET /points/:id anonymously' do
    it 'serves an approved point' do
      point = create(:point, user: author, status: 'approved')

      get point_path(point)

      expect(response).to have_http_status(:ok)
    end

    %w[draft pending declined changes-requested approved-not-found].each do |status|
      it "does not serve a #{status} point" do
        point = create(:point, user: author, status: status)

        get point_path(point)

        expect(response).not_to have_http_status(:ok)
      end
    end

    it 'still serves a pending point to a signed-in user' do
      point = create(:point, user: author, status: 'pending')
      sign_in curator

      get point_path(point)

      expect(response).to have_http_status(:ok)
    end
  end
end
