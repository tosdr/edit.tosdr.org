require 'rails_helper'

RSpec.describe 'Point review queue', type: :request do
  let(:curator) { create(:user_confirmed) }
  let(:author) { create(:user_confirmed) }

  before do
    host! 'example.com'
    sign_in curator
  end

  it 'shows the oldest pending point that was not authored by the curator' do
    own_point = create(:point, user: curator, status: 'pending', case: create(:case, title: 'Own pending point'))
    reviewable_point = create(:point, user: author, status: 'pending', case: create(:case, title: 'Reviewable pending point'))
    newer_point = create(:point, user: author, status: 'pending', case: create(:case, title: 'Newer pending point'))

    own_point.update_columns(updated_at: 3.days.ago)
    reviewable_point.update_columns(updated_at: 2.days.ago)
    newer_point.update_columns(updated_at: 1.day.ago)

    get review_queue_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Reviewable pending point')
    expect(response.body).not_to include('Own pending point')
  end

  it 'returns to the queue after submitting a queued review' do
    point = create(:point, user: author, status: 'pending')

    post post_review_path(point), params: {
      queue: '1',
      point: {
        status: 'approved',
        point_change: 'Looks good.'
      }
    }

    expect(response).to redirect_to(review_queue_path)
    expect(point.reload.status).to eq('approved')
  end

  it 'filters pending points by author, level, excluded services, and skipped point' do
    service = create(:service, name: 'Included service')
    excluded_service = create(:service, name: 'Excluded service')
    other_author = create(:user_confirmed, username: 'other_author')
    author.update_columns(level: 2)
    other_author.update_columns(level: 3)

    skipped_point = create(:point, user: author, service: service, status: 'pending', case: create(:case, title: 'Skipped point'))
    matching_point = create(:point, user: author, service: service, status: 'pending', case: create(:case, title: 'Matching point'))
    excluded_service_point = create(:point, user: author, service: excluded_service, status: 'pending', case: create(:case, title: 'Excluded service point'))
    other_author_point = create(:point, user: other_author, service: service, status: 'pending', case: create(:case, title: 'Other author point'))
    author.update_columns(level: 2)
    other_author.update_columns(level: 3)

    skipped_point.update_columns(updated_at: 4.days.ago)
    matching_point.update_columns(updated_at: 3.days.ago)
    excluded_service_point.update_columns(updated_at: 2.days.ago)
    other_author_point.update_columns(updated_at: 1.day.ago)

    get review_queue_path, params: {
      author_id: author.id,
      level: 2,
      excluded_service_ids: [excluded_service.id],
      skip_id: skipped_point.id
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Matching point')
    expect(response.body).not_to include('Skipped point')
    expect(response.body).not_to include('Excluded service point')
    expect(response.body).not_to include('Other author point')
  end
end
