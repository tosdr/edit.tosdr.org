require 'rails_helper'

RSpec.describe 'Cases', type: :request do
  before { host! 'example.com' }

  describe 'GET /cases/list_all' do
    it 'includes each case with its topic, total point count and approved point count' do
      topic = create(:topic)
      busy_case = create(:case, topic: topic, classification: 'bad', score: 70)
      empty_case = create(:case, topic: topic, classification: 'good', score: 20)

      create_list(:point, 2, case: busy_case, status: 'approved')
      create(:point, case: busy_case, status: 'pending')
      create(:point, case: busy_case, status: 'declined')
      create(:point, case: busy_case, status: 'deleted')

      get list_all_cases_path

      expect(response).to have_http_status(:ok)
      body = response.parsed_body.index_by { |entry| entry['case']['id'] }

      expect(body[busy_case.id]).to include(
        'pointbox' => 'point-bad',
        'topic' => { 'id' => topic.id, 'title' => topic.title },
        'points_count' => 4,
        'approved_points_count' => 2
      )
      expect(body[busy_case.id]['case']['score']).to eq(70)

      expect(body[empty_case.id]).to include('points_count' => 0, 'approved_points_count' => 0)
    end
  end

  describe 'GET /cases/:id' do
    let(:the_case) { create(:case, classification: 'bad') }
    let(:author) { create(:user_confirmed) }

    before do
      create(:point, case: the_case, user: author, status: 'approved', title: 'Approved point')
      create(:point, case: the_case, user: author, status: 'pending', title: 'Pending point')
    end

    it 'shows points of every status by default' do
      get case_path(the_case)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Approved point', 'Pending point')
      expect(response.body).to include('<option selected="selected" value="">all</option>')
    end

    it 'only shows points with the requested status' do
      get case_path(the_case, status: 'approved')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Approved point')
      expect(response.body).not_to include('Pending point')
      expect(response.body).to include('<option selected="selected" value="approved">approved</option>')
    end

    it 'ignores an unknown status and shows every point' do
      get case_path(the_case, status: 'bogus')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Approved point', 'Pending point')
      expect(response.body).to include('<option selected="selected" value="">all</option>')
    end
  end
end
