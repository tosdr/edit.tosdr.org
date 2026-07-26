require 'rails_helper'

RSpec.describe 'Point soft delete', type: :request do
  # The base user factory is admin + curator, so non-admin roles are opted out explicitly.
  let(:admin) { create(:user_confirmed) }
  let(:curator) { create(:user_confirmed, admin: false) }
  let(:author) { create(:user_confirmed, admin: false, curator: false) }

  before do
    host! 'example.com'
  end

  it 'lets an admin soft delete a point they did not author' do
    sign_in admin
    point = create(:point, user: author, status: 'approved')

    delete point_path(point)

    expect(response).to redirect_to(service_path(point.service))
    expect(Point.with_deleted.find(point.id).status).to eq('deleted')
    expect(Point.where(id: point.id)).to be_empty
  end

  it 'records a comment and a version for the deletion' do
    sign_in admin
    point = create(:point, user: author, status: 'approved')

    delete point_path(point)

    expect(PointComment.where(point_id: point.id).last.summary).to eq('Point deleted by an admin')
    expect(PointComment.where(point_id: point.id).last.user_id).to eq(admin.id)
    expect(point.versions.last.changeset['status']).to eq(%w[approved deleted])
  end

  it 'drops the deleted point from the author level count' do
    sign_in admin
    point = create(:point, user: author, status: 'approved')
    author.refresh_level_from_points!
    expect(author.reload.approved_points_count).to eq(1)

    delete point_path(point)

    expect(author.reload.approved_points_count).to eq(0)
  end

  it 'does not let a curator who is not an admin delete a point' do
    sign_in curator
    point = create(:point, user: author, status: 'approved')

    delete point_path(point)

    expect(response).to redirect_to(root_path)
    expect(Point.with_deleted.find(point.id).status).to eq('approved')
  end

  it 'does not let the author delete their own point' do
    sign_in author
    point = create(:point, user: author, status: 'approved')

    delete point_path(point)

    expect(response).to redirect_to(root_path)
    expect(Point.with_deleted.find(point.id).status).to eq('approved')
  end

  it 'requires a signed in user' do
    point = create(:point, user: author, status: 'approved')

    delete point_path(point)

    expect(response.location).to include(new_user_session_path)
    expect(Point.with_deleted.find(point.id).status).to eq('approved')
  end

  it 'shows the delete button on the point page to admins only' do
    point = create(:point, user: author, status: 'approved')

    sign_in admin
    get point_path(point)
    expect(response.body).to include('Delete this point?')

    sign_out admin
    sign_in curator
    get point_path(point)
    expect(response.body).not_to include('Delete this point?')
  end

  it 'is not reachable for a point that is already deleted' do
    sign_in admin
    point = create(:point, user: author, status: 'approved')
    point.deprecate!

    delete point_path(point)

    expect(response).to have_http_status(:not_found)
  end
end
