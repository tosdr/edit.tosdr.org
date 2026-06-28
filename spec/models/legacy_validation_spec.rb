require 'rails_helper'

# Locks in the "grandfathering" behavior: legacy rows with blank/duplicate fields
# (predating the presence/uniqueness validations) stay editable, while create paths and
# edits that actually change a field still reject bad data.
describe 'Selective (grandfathered) validations', type: :model do
  before { Rails.application.routes.default_url_options[:host] = 'example.com' }

  describe 'Document' do
    it 'rejects a brand-new document with blank content fields' do
      doc = build(:document, text: '', selector: '')

      expect(doc).not_to be_valid
      expect(doc.errors[:text]).to be_present
      expect(doc.errors[:selector]).to be_present
    end

    it 'saves a legacy document with blank text/selector when those fields are untouched' do
      doc = create(:document)
      doc.update_columns(text: '', selector: '') # simulate a row predating the validations

      doc.reload.last_crawl_date = Time.current
      expect(doc).to be_valid
      expect(doc.save).to be(true)
    end

    it 'still rejects blanking a previously-populated field on edit' do
      doc = create(:document)

      doc.selector = ''
      expect(doc).not_to be_valid
      expect(doc.errors[:selector]).to be_present
    end

    it 'skips the location uniqueness check when url/selector are untouched' do
      first = create(:document)
      legacy = create(:document)
      legacy.update_columns(url: first.url, selector: first.selector) # legacy duplicate location

      legacy.reload.last_crawl_date = Time.current
      expect(legacy).to be_valid
    end

    it 'still enforces the location uniqueness check when url/selector change to a duplicate' do
      first = create(:document)
      other = create(:document)

      other.url = first.url
      other.selector = first.selector
      expect(other).not_to be_valid
      expect(other.errors[:url]).to be_present
    end
  end

  describe 'Service' do
    it 'rejects a brand-new service with a blank name' do
      service = build(:service, name: '')

      expect(service).not_to be_valid
      expect(service.errors[:name]).to be_present
    end

    it 'saves a legacy service with a duplicate name when the name is untouched' do
      original = create(:service)
      legacy = create(:service)
      legacy.update_columns(name: original.name) # simulate a legacy duplicate

      legacy.reload.url = 'https://legacy-grandfather.test'
      expect(legacy).to be_valid
    end

    it 'still rejects changing a name to one that already exists' do
      original = create(:service)
      other = create(:service)

      other.name = original.name
      expect(other).not_to be_valid
      expect(other.errors[:name]).to be_present
    end
  end

  describe 'Point' do
    it 'rejects a brand-new point with a blank title' do
      point = build(:point, title: '')

      expect(point).not_to be_valid
      expect(point.errors[:title]).to be_present
    end

    it 'saves a legacy point with a blank title when the title is untouched' do
      point = create(:point)
      point.update_columns(title: '') # simulate a legacy row

      point.reload.source = 'https://legacy-grandfather.test'
      expect(point).to be_valid
    end

    it 'still rejects blanking the title on edit' do
      point = create(:point)

      point.title = ''
      expect(point).not_to be_valid
      expect(point.errors[:title]).to be_present
    end
  end
end
