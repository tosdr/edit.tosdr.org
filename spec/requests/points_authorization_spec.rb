require 'rails_helper'

# Regression coverage for the annotate/quote authorization holes:
#   * status was mass-assignable from top-level params, so a contributor could post
#     status=approved-not-found and have #quote promote the new point to 'approved'
#     (self-approval -> level escalation -> published dataset).
#   * #quote authorized the *service* (ServicePolicy#quote? is `true` for everyone) while
#     mutating whichever point id the request named, so any point was overwritable.
#   * PointPolicy#show? was `true`, exposing non-approved points to logged-out visitors.
RSpec.describe 'Point authorization', type: :request do
  # The base user factory is admin + curator, so ordinary contributors opt out explicitly.
  let(:author) { create(:user_confirmed, admin: false, curator: false) }
  let(:attacker) { create(:user_confirmed, admin: false, curator: false) }
  let(:curator) { create(:user_confirmed, admin: false) }

  let(:service) { create(:service) }
  let(:document) { create(:document, service: service, text: 'Example policy text for test points.') }
  let(:case_ref) { create(:case) }

  before { host! 'example.com' }

  def quote_params(extra = {})
    { quoteCaseId: case_ref.id, document_id: document.id, quote_start: 0, quote_end: 10 }.merge(extra)
  end

  describe 'POST /services/:id/annotate (self-approval)' do
    it 'ignores a client-supplied status and files the new point as pending' do
      sign_in attacker

      post annotate_path(service), params: quote_params(status: 'approved-not-found')

      point = Point.order(:id).last
      expect(point.user).to eq(attacker)
      expect(point.status).to eq('pending')
    end

    it 'does not escalate the author to level two off a self-approved point' do
      sign_in attacker

      post annotate_path(service), params: quote_params(status: 'approved-not-found')

      expect(attacker.reload.approved_points_count).to eq(0)
      expect(attacker).not_to be_level_two
    end

    it 'still files a plain annotation as pending' do
      sign_in attacker

      post annotate_path(service), params: quote_params

      expect(Point.order(:id).last.status).to eq('pending')
    end
  end

  describe 'POST /services/:id/annotate (point_id IDOR)' do
    let!(:victim_point) do
      create(:point, user: author, service: service, document: document,
                     status: 'approved', quote_text: 'Example policy')
    end

    it "refuses to rewrite another user's point" do
      sign_in attacker

      post annotate_path(service), params: quote_params(point_id: victim_point.id)

      victim_point.reload
      expect(victim_point.status).to eq('approved')
      expect(victim_point.quote_text).to eq('Example policy')
    end

    it 'lets the author re-quote their own point, back through review' do
      sign_in author

      post annotate_path(service), params: quote_params(point_id: victim_point.id)

      victim_point.reload
      expect(victim_point.status).to eq('pending')
      expect(victim_point.quote_text).to eq('Example po')
    end

    it 'restores an approved-not-found point to approved once its quote is relocated' do
      victim_point.update_column(:status, 'approved-not-found')
      sign_in author

      post annotate_path(service), params: quote_params(point_id: victim_point.id)

      expect(victim_point.reload.status).to eq('approved')
    end

    it 'denies an unrelated user the re-quote form' do
      sign_in attacker

      get annotate_path(service), params: { point_id: victim_point.id }

      expect(response).to be_redirect
      expect(flash[:alert]).to eq('You are not authorized to perform this action.')
    end

    it 'denies rather than crashing on an anonymously authored point' do
      orphan = create(:point, user: nil, service: service, document: document, status: 'approved')
      sign_in attacker

      post annotate_path(service), params: quote_params(point_id: orphan.id)

      expect(response).to be_redirect
      expect(orphan.reload.status).to eq('approved')
    end
  end

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
