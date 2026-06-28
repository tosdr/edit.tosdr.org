require 'rails_helper'

describe 'Deprecation (soft-delete)', type: :model do
  describe 'NULL-safe default scope' do
    it 'hides deleted-status rows but keeps NULL-status rows visible' do
      visible = create(:service) # status defaults to NULL
      deleted = create(:service, status: 'deleted')

      expect(Service.all).to include(visible)
      expect(Service.all).not_to include(deleted)
      expect(Service.with_deleted).to include(deleted)
    end

    it 'allows the point status enum to include deleted' do
      point = create(:point, status: 'pending')

      expect { point.update!(status: 'deleted') }.not_to raise_error
    end

    it 'hides a deleted point from associations but keeps it under with_deleted' do
      document = create(:document)
      point = create(:point, document: document, service: document.service, status: 'approved')

      point.update!(status: 'deleted')

      expect(document.points.reload).not_to include(point)
      expect(Point.with_deleted.where(document_id: document.id)).to include(point)
    end
  end

  describe 'Document#deprecate!' do
    it 'soft-deletes the document and cascades to its points without hard deletion' do
      document = create(:document)
      approved = create(:point, document: document, service: document.service, status: 'approved')
      pending = create(:point, document: document, service: document.service, status: 'pending')

      expect { document.deprecate! }
        .to change { Document.count }.by(-1)
        .and change { Point.count }.by(-2)

      expect(Document.with_deleted.find(document.id).status).to eq('deleted')
      expect(Point.with_deleted.find(approved.id).status).to eq('deleted')
      expect(Point.with_deleted.find(pending.id).status).to eq('deleted')
    end

    it 'soft-deletes a legacy document whose required fields are blank (regression)' do
      document = create(:document)
      point = create(:point, document: document, service: document.service, status: 'approved')
      # Simulate legacy rows that predate the text/selector presence validations.
      document.update_columns(text: '', selector: '')

      expect { document.deprecate! }.not_to raise_error
      expect(Document.with_deleted.find(document.id).status).to eq('deleted')
      expect(Point.with_deleted.find(point.id).status).to eq('deleted')
    end

    it 'soft-deletes a point with legacy-invalid content (blank title)' do
      document = create(:document)
      point = create(:point, document: document, service: document.service, status: 'approved')
      point.update_columns(title: '')

      expect { document.deprecate! }.not_to raise_error
      expect(Point.with_deleted.find(point.id).status).to eq('deleted')
    end

    it 'refreshes the author level when an approved point is deprecated (proves per-point update!)' do
      author = create(:user_confirmed)
      document = create(:document)
      create(:point, user: author, document: document, service: document.service, status: 'approved')

      expect(author.reload.approved_points_count).to eq(1)

      document.deprecate!

      expect(author.reload.approved_points_count).to eq(0)
      expect(author.level).to eq(1)
    end
  end

  describe 'Service#deprecate!' do
    it 'cascades through documents down to points' do
      service = create(:service)
      doc_a = create(:document, service: service)
      doc_b = create(:document, service: service)
      point_a = create(:point, document: doc_a, service: service, status: 'approved')
      point_b = create(:point, document: doc_b, service: service, status: 'pending')

      service.deprecate!

      expect(Service.with_deleted.find(service.id).status).to eq('deleted')
      expect(Document.with_deleted.find(doc_a.id).status).to eq('deleted')
      expect(Document.with_deleted.find(doc_b.id).status).to eq('deleted')
      expect(Point.with_deleted.find(point_a.id).status).to eq('deleted')
      expect(Point.with_deleted.find(point_b.id).status).to eq('deleted')

      expect(Service.exists?(service.id)).to be(false)
    end
  end

  describe 'document-less points' do
    it 'Service#deprecate! deprecates a point that belongs to the service but has no document' do
      service = create(:service)
      point = create(:point, service: service, document: nil, status: 'pending')

      service.deprecate!

      expect(Point.with_deleted.find(point.id).status).to eq('deleted')
    end
  end

  describe 'Point.deprecate_orphans!' do
    it 'deprecates an active point whose service was already deleted' do
      service = create(:service)
      point = create(:point, service: service, document: nil, status: 'approved')
      service.update_columns(status: 'deleted') # simulate an orphan (no cascade)

      Point.deprecate_orphans!

      expect(Point.with_deleted.find(point.id).status).to eq('deleted')
    end

    it 'deprecates an active point whose document was already deleted' do
      document = create(:document)
      point = create(:point, document: document, service: document.service, status: 'pending')
      document.update_columns(status: 'deleted') # simulate an orphan (no cascade)

      Point.deprecate_orphans!

      expect(Point.with_deleted.find(point.id).status).to eq('deleted')
    end

    it 'leaves healthy points untouched' do
      point = create(:point, status: 'approved')

      Point.deprecate_orphans!

      expect(point.reload.status).to eq('approved')
    end
  end

  describe 'Document uniqueness under the default scope' do
    # location_uniqueness_check builds an absolute document_url in its error message.
    before { Rails.application.routes.default_url_options[:host] = 'example.com' }

    it 'blocks a second active document at the same url+selector' do
      active = create(:document)
      duplicate = build(:document, url: active.url, selector: active.selector, service: active.service)

      expect(duplicate).not_to be_valid
    end

    it 'does not let a deprecated document block re-creation at the same url+selector' do
      original = create(:document)
      original.deprecate!

      replacement = build(:document, url: original.url, selector: original.selector, service: original.service)

      expect(replacement).to be_valid
    end
  end
end
