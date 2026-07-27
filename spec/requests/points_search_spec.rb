require 'rails_helper'

# The soft-delete default scopes are raw SQL. When a Ransack search joins points to
# services, Rails folds the joined model's default scope into the JOIN's ON clause, so
# an unqualified `status` there is ambiguous (both tables have the column) and Postgres
# raises PG::AmbiguousColumn. These specs run a real search over the join.
RSpec.describe 'Point search across services', type: :request do
  let(:user) { create(:user_confirmed) }
  let(:matching_service) { create(:service, name: 'Searchable Widgets') }
  let(:other_service) { create(:service, name: 'Unrelated Gadgets') }

  before do
    host! 'example.com'
    sign_in user
  end

  it 'filters my contributions by service name' do
    create(:point, user: user, service: matching_service, status: 'approved')
    create(:point, user: user, service: other_service, status: 'approved')

    get my_points_path, params: { q: { service_name_cont: 'Searchable' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Searchable Widgets')
    expect(response.body).not_to include('Unrelated Gadgets')
  end

  it 'filters the point index by service name' do
    create(:point, user: user, service: matching_service, status: 'approved')
    create(:point, user: user, service: other_service, status: 'approved')

    get points_path, params: { q: { service_name_cont: 'Searchable' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Searchable Widgets')
    expect(response.body).not_to include('Unrelated Gadgets')
  end

  it 'keeps other contributors points out of my contributions when searching' do
    other_user = create(:user_confirmed)
    mine = create(:point, user: user, service: matching_service, status: 'approved')
    theirs = create(:point, user: other_user, service: matching_service, status: 'approved')

    get my_points_path, params: { q: { service_name_cont: 'Searchable' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(mine.title)
    expect(response.body).not_to include(theirs.title)
  end

  it 'submits the my contributions search back to my contributions' do
    create(:point, user: user, service: matching_service, status: 'approved')

    get my_points_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("action=\"#{my_points_path}\"")
  end

  it 'leaves soft deleted points and points on soft deleted services out of the results' do
    kept = create(:point, user: user, service: matching_service, status: 'approved')
    deleted_point = create(:point, user: user, service: matching_service, status: 'approved')
    deleted_point.update_column(:status, 'deleted')

    deleted_service = create(:service, name: 'Searchable Leftovers')
    orphan = create(:point, user: user, service: deleted_service, status: 'approved')
    deleted_service.update_column(:status, 'deleted')

    get my_points_path, params: { q: { service_name_cont: 'Searchable' } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(kept.title)
    expect(response.body).not_to include(deleted_point.title)
    expect(response.body).not_to include(orphan.title)
  end
end
