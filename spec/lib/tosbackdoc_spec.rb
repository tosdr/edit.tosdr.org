require 'rails_helper'
require Rails.root.join('lib/tosbackdoc')

RSpec.describe TOSBackDoc do
  describe '#initialize' do
    it 'raises a clear error when required path fields are missing' do
      expect { described_class.new(url: 'https://example.test') }.to raise_error(ArgumentError, /site is required/)
    end
  end

  describe '#scrape' do
    it 'records missing crawler API key as a crawler error instead of an empty crawl' do
      doc = described_class.new(site: 'example.test', name: 'Privacy Policy', url: 'https://example.test/privacy')
      allow(ENV).to receive(:[]).with('CRAWLER_API_KEY').and_return(nil)

      doc.scrape

      expect(doc.crawler_error?).to eq(true)
      expect(doc.crawl_empty?).to eq(false)
    end
  end
end
