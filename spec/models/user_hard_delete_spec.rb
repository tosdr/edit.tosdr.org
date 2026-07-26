require 'rails_helper'

describe 'User#hard_delete', type: :model do
  # The real anonymous account is id 1; the constant is stubbed so the spec does not have to
  # insert a row at a fixed id and fight the users sequence.
  let!(:anonymous) { create(:user) }
  let(:user) { create(:user) }

  before { stub_const('User::ANONYMOUS_USER_ID', anonymous.id) }

  it 'reassigns soft-deleted contributions so the delete does not violate a foreign key' do
    service = create(:service, user: user)
    document = create(:document, service: service, user: user)
    point = create(:point, document: document, service: service, user: user, status: 'approved')

    document.deprecate! # cascades to the point
    service.update_columns(status: 'deleted')

    expect { user.destroy! }.not_to raise_error

    expect(User.exists?(user.id)).to be(false)
    expect(Document.with_deleted.find(document.id).user_id).to eq(anonymous.id)
    expect(Point.with_deleted.find(point.id).user_id).to eq(anonymous.id)
    expect(Service.with_deleted.find(service.id).user_id).to eq(anonymous.id)
  end

  it 'reassigns still-active contributions' do
    service = create(:service, user: user)
    document = create(:document, service: service, user: user)
    point = create(:point, document: document, service: service, user: user, status: 'approved')

    user.destroy!

    expect(document.reload.user_id).to eq(anonymous.id)
    expect(point.reload.user_id).to eq(anonymous.id)
    expect(service.reload.user_id).to eq(anonymous.id)
  end

  it 'drops the vetoes of a user deleted without callbacks (registrations#destroy path)' do
    point = create(:point, status: 'pending')
    PointVeto.create!(point: point, user: user)

    user.hard_delete
    expect { user.delete }.not_to raise_error

    expect(PointVeto.where(user_id: user.id)).to be_empty
    expect(User.exists?(user.id)).to be(false)
  end
end
