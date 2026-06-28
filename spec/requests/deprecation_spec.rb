require 'rails_helper'

RSpec.describe 'Deprecation', type: :request do
  let(:admin)   { create(:user_confirmed, admin: true, curator: true) }
  let(:curator) { create(:user_confirmed, admin: false, curator: true) }
  let(:plain)   { create(:user_confirmed, admin: false, curator: false) }

  before { host! 'example.com' }

  describe 'POST /documents/:id/deprecate' do
    it 'blocks a curator when the document has points and tells them to ask an admin' do
      document = create(:document)
      create(:point, document: document, service: document.service, status: 'pending')
      sign_in curator

      post document_deprecate_path(document)

      expect(response).to redirect_to(document_path(document))
      expect(flash[:alert]).to match(/ask an admin/i)
      expect(document.reload.status).not_to eq('deleted')
    end

    it 'lets a curator deprecate a document with no points' do
      document = create(:document)
      sign_in curator

      post document_deprecate_path(document)

      expect(response).to redirect_to(annotate_path(document.service))
      expect(Document.exists?(document.id)).to be(false)
      expect(Document.with_deleted.find(document.id).status).to eq('deleted')
    end

    it 'lets an admin deprecate a document that has points' do
      document = create(:document)
      create(:point, document: document, service: document.service, status: 'approved')
      sign_in admin

      post document_deprecate_path(document)

      expect(Document.exists?(document.id)).to be(false)
      expect(Document.with_deleted.find(document.id).status).to eq('deleted')
    end

    it 'is not authorized for a plain user' do
      document = create(:document)
      sign_in plain

      post document_deprecate_path(document)

      expect(response).to redirect_to(root_path)
      expect(document.reload.status).not_to eq('deleted')
    end
  end

  describe 'POST /services/:id/deprecate' do
    it 'blocks a curator when the service has points' do
      service = create(:service)
      document = create(:document, service: service)
      create(:point, document: document, service: service, status: 'pending')
      sign_in curator

      post service_deprecate_path(service)

      expect(response).to redirect_to(service_path(service))
      expect(flash[:alert]).to match(/ask an admin/i)
      expect(service.reload.status).not_to eq('deleted')
    end

    it 'lets an admin deprecate a service and cascades to documents and points' do
      service = create(:service)
      document = create(:document, service: service)
      point = create(:point, document: document, service: service, status: 'approved')
      sign_in admin

      post service_deprecate_path(service)

      expect(response).to redirect_to(services_path)
      expect(Service.exists?(service.id)).to be(false)
      expect(Service.with_deleted.find(service.id).status).to eq('deleted')
      expect(Document.with_deleted.find(document.id).status).to eq('deleted')
      expect(Point.with_deleted.find(point.id).status).to eq('deleted')
    end
  end

  describe 'Deprecate buttons render for authorized users' do
    it 'shows a Deprecate button on the document show page' do
      document = create(:document)
      sign_in curator

      get document_path(document)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Deprecate Document')
    end

    it 'shows a Deprecate button on the service show page' do
      service = create(:service)
      sign_in curator

      get service_path(service)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Deprecate Service')
    end
  end

  describe 'visibility of deprecated entities' do
    it 'omits a deprecated service from the services index and makes its show page unreachable' do
      service = create(:service)
      service.deprecate!

      get services_path
      expect(response.body).not_to include(service.name)

      get service_path(service)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'orphan documents (service deprecated out-of-band)' do
    # A document whose service was marked 'deleted' directly in the DB stays active (its own
    # status is untouched) but has a nil service, since the association applies Service's
    # default scope. Until the daily backfill hides it, the read paths must not 500.
    it 'does not 500 the documents index and omits the orphan row' do
      healthy = create(:document)
      orphan = create(:document, url: 'http://orphan-doc.example') # < 30 chars: renders un-truncated
      orphan.service.update_columns(status: 'deleted')

      get documents_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(healthy.service.name)
      expect(response.body).not_to include('orphan-doc.example')
    end

    it 'redirects the document show page for an orphan instead of 500ing' do
      document = create(:document)
      document.service.update_columns(status: 'deleted')

      get document_path(document)

      expect(response).to redirect_to(documents_path)
      expect(flash[:alert]).to match(/no longer available/i)
    end
  end

  describe 'removed hard-delete / nuke routes' do
    it 'no longer routes DELETE documents, DELETE services, or POST nuke (they fall through to the catch-all)' do
      expect(Rails.application.routes.recognize_path('/documents/1', method: :delete))
        .to include(controller: 'application', action: 'not_found')
      expect(Rails.application.routes.recognize_path('/documents/1/nuke', method: :post))
        .to include(controller: 'application', action: 'not_found')
      expect(Rails.application.routes.recognize_path('/services/1', method: :delete))
        .to include(controller: 'application', action: 'not_found')
    end
  end
end
