require 'rails_helper'

# Regression coverage: #create forced 'pending' for ordinary users, but #update permitted
# :status and DocumentTypePolicy#edit? grants the owner -- so a submitter could create a
# request and immediately PATCH it to 'approved', bypassing the moderation queue.
RSpec.describe 'DocumentType authorization', type: :request do
  # The base user factory is admin + curator, so ordinary contributors opt out explicitly.
  let(:submitter) { create(:user_confirmed, admin: false, curator: false) }
  let(:curator) { create(:user_confirmed, admin: false) }

  before { host! 'example.com' }

  def valid_attributes(extra = {})
    { name: 'EU Privacy Policy', description: 'concerns EU end user personal data' }.merge(extra)
  end

  it 'files an ordinary submission as pending even when status is posted' do
    sign_in submitter

    post document_types_path, params: { document_type: valid_attributes(status: 'approved') }

    expect(DocumentType.order(:id).last.status).to eq('pending')
  end

  it 'refuses to let the owner approve their own submission via update' do
    sign_in submitter
    document_type = DocumentType.create!(valid_attributes(status: 'pending', user: submitter))

    patch document_type_path(document_type), params: { document_type: valid_attributes(status: 'approved') }

    expect(document_type.reload.status).to eq('pending')
  end

  it 'still lets the owner edit the fields they own' do
    sign_in submitter
    document_type = DocumentType.create!(valid_attributes(status: 'pending', user: submitter))

    patch document_type_path(document_type),
          params: { document_type: valid_attributes(description: 'a revised description') }

    document_type.reload
    expect(document_type.description).to eq('a revised description')
    expect(document_type.status).to eq('pending')
  end

  it 'refuses to let the owner hand the record to another account' do
    sign_in submitter
    document_type = DocumentType.create!(valid_attributes(status: 'pending', user: submitter))

    patch document_type_path(document_type), params: { document_type: valid_attributes(user_id: curator.id) }

    expect(document_type.reload.user_id).to eq(submitter.id)
  end

  it 'lets a curator set the status through update' do
    sign_in curator
    document_type = DocumentType.create!(valid_attributes(status: 'pending', user: submitter))

    patch document_type_path(document_type), params: { document_type: valid_attributes(status: 'approved') }

    expect(document_type.reload.status).to eq('approved')
  end
end
