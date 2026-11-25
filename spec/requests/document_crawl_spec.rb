require 'rails_helper'

# End-to-end coverage for the paths that fetch document text from the OTA crawler: the
# "Crawl Document" button, editing a document's URL/selector, and creating a document. Saving
# new text reconciles the points against it (Document#reconcile_points!).
RSpec.describe 'Document crawl', type: :request do
  let(:ota_url) { 'http://ota.example.test/fetch' }
  let(:old_text) { 'Old policy: we collect your data and keep it forever.' }
  let(:new_text) { 'Brand new policy with completely rewritten wording.' }
  let(:quote) { 'we collect your data' }

  before do
    host! 'example.com'
    ENV['OTA_URL'] = ota_url
    ENV['OTA_API_SECRET'] = 'test-secret'
    sign_in create(:user_confirmed)
  end

  after do
    ENV.delete('OTA_URL')
    ENV.delete('OTA_API_SECRET')
  end

  # The OTA crawler returns the fetched document text as a JSON string.
  def stub_crawler_text(text)
    stub_request(:post, ota_url)
      .to_return(status: 200, body: text.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def quote_point(document, status:, text: old_text)
    create(:point, document: document, service: document.service, status: status, quote_text: quote,
                   quote_start: text.index(quote), quote_end: text.index(quote) + quote.length)
  end

  describe 'POST /documents/:id/crawl' do
    it 'crawls, flags points missing from the new text, and reports the count' do
      stub_crawler_text(new_text)
      document = create(:document, text: old_text)
      point = quote_point(document, status: 'approved')

      post document_crawl_path(document)

      expect(response).to redirect_to(document_path(document))
      expect(document.reload.text).to eq(new_text)
      expect(document.text_version).to eq(Digest::SHA256.hexdigest(new_text))
      expect(document.last_crawl_date).to be_present
      expect(point.reload.status).to eq('approved-not-found')
      expect(flash[:notice]).to include('Crawl successful. Document text updated. 1 point missing from the new text.')
    end

    it 'relocates a quote that moved in the new text and keeps its status' do
      stub_crawler_text("Preamble added. #{old_text}")
      document = create(:document, text: old_text)
      point = quote_point(document, status: 'approved')

      post document_crawl_path(document)

      point.reload
      expect(point.status).to eq('approved')
      expect(point.quote_start).to eq(document.reload.text.index(quote))
      expect(flash[:notice]).to include('0 points missing from the new text. 1 quote relocated.')
    end

    it 'restores a previously missing point whose quote is back in the new text' do
      stub_crawler_text(old_text)
      document = create(:document, text: new_text)
      point = quote_point(document, status: 'approved-not-found')

      post document_crawl_path(document)

      expect(point.reload.status).to eq('approved')
      expect(flash[:notice]).to include('1 previously missing point found again and restored.')
    end

    it 'reports an unchanged text and still records the crawl date' do
      stub_crawler_text(old_text)
      document = create(:document, text: old_text)

      post document_crawl_path(document)

      expect(flash[:notice]).to eq('Crawl successful. Document text unchanged.')
      expect(document.reload.last_crawl_date).to be_present
      expect(document.text_version).to eq(Digest::SHA256.hexdigest(old_text))
    end

    it 'sends the URL and selector as valid JSON, even when the selector contains quotes' do
      selector = 'div[class="terms"] > p'
      request_stub = stub_request(:post, ota_url)
                     .with(body: { fetch: 'https://example.com/tos', select: selector }.to_json,
                           headers: { 'Authorization' => 'Bearer test-secret' })
                     .to_return(status: 200, body: new_text.to_json)
      document = create(:document, text: old_text, url: 'https://example.com/tos', selector: selector)

      post document_crawl_path(document)

      expect(request_stub).to have_been_requested
      expect(document.reload.text).to eq(new_text)
    end

    shared_examples 'a failed crawl' do |expected_message|
      it 'shows the failure after the redirect and leaves the document alone' do
        document = create(:document, text: old_text)
        point = quote_point(document, status: 'approved')

        post document_crawl_path(document)

        expect(response).to redirect_to(document_path(document))
        expect(flash[:notice]).to be_nil
        expect(flash[:warning]).to include('Crawl failed:')
        expect(flash[:warning]).to include(expected_message)
        expect(flash[:warning]).not_to include('successful')
        document.reload
        expect(document.text).to eq(old_text)
        expect(document.text_version).to eq(Digest::SHA256.hexdigest(old_text))
        expect(document.last_crawl_date).to be_nil
        expect(point.reload.status).to eq('approved')
      end
    end

    context 'when the crawler answers with an HTTP error' do
      before { stub_request(:post, ota_url).to_return(status: [502, 'Bad Gateway']) }

      it_behaves_like 'a failed crawl', 'the crawler responded with HTTP 502 Bad Gateway.'
    end

    context 'when the crawler drops the connection' do
      before { stub_request(:post, ota_url).to_raise(EOFError) }

      it_behaves_like 'a failed crawl', 'check the URL and selector'
    end

    context 'when the crawler times out' do
      before { stub_request(:post, ota_url).to_timeout }

      it_behaves_like 'a failed crawl', 'the crawler timed out'
    end

    context 'when the crawler returns empty text' do
      before { stub_crawler_text('') }

      it_behaves_like 'a failed crawl', 'the crawler returned no text for this URL and selector.'
    end

    context 'when the crawler returns something other than JSON' do
      before { stub_request(:post, ota_url).to_return(status: 200, body: '<html>oops</html>') }

      it_behaves_like 'a failed crawl', 'the crawler returned a response that could not be read.'
    end

    it 'escapes error details, since flashes are rendered raw' do
      stub_request(:post, ota_url).to_raise(StandardError.new('<script>alert(1)</script>'))
      document = create(:document, text: old_text)

      post document_crawl_path(document)

      expect(flash[:warning]).to include('&lt;script&gt;')
      expect(flash[:warning]).not_to include('<script>')
    end

    it 'does not call the crawler for a legacy document without a selector' do
      document = create(:document, text: old_text)
      document.update_columns(selector: nil)

      post document_crawl_path(document)

      expect(a_request(:post, ota_url)).not_to have_been_made
      expect(flash[:warning]).to include('needs both a URL and a CSS selector')
    end

    it 'reports a missing crawler configuration instead of raising' do
      ENV.delete('OTA_URL')
      document = create(:document, text: old_text)

      post document_crawl_path(document)

      expect(flash[:warning]).to include('the crawler is not configured')
    end
  end

  describe 'PATCH /documents/:id' do
    it 'recrawls a changed selector and reconciles the points' do
      stub_crawler_text(new_text)
      document = create(:document, text: old_text)
      point = quote_point(document, status: 'pending')

      patch document_path(document), params: { document: { selector: 'main' } }

      expect(response).to redirect_to(document_path(document))
      document.reload
      expect(document.selector).to eq('main')
      expect(document.text).to eq(new_text)
      expect(point.reload.status).to eq('pending-not-found')
      expect(flash[:notice]).to include('Document updated and recrawled. 1 point missing from the new text.')
    end

    it 'keeps the old URL and text when the recrawl fails' do
      stub_request(:post, ota_url).to_return(status: [502, 'Bad Gateway'])
      document = create(:document, text: old_text, url: 'https://example.com/old')

      patch document_path(document), params: { document: { url: 'https://example.com/new' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Crawl failed: the crawler responded with HTTP 502 Bad Gateway.')
      document.reload
      expect(document.url).to eq('https://example.com/old')
      expect(document.text).to eq(old_text)
    end

    it 'does not crawl when the location is unchanged' do
      document = create(:document, text: old_text)

      patch document_path(document), params: { document: { name: 'Renamed policy' } }

      expect(a_request(:post, ota_url)).not_to have_been_made
      expect(document.reload.name).to eq('Renamed policy')
      expect(flash[:notice]).to eq('Document updated.')
    end
  end

  describe 'POST /documents' do
    let(:service) { create(:service) }
    let(:params) do
      { document: { service_id: service.id, name: 'Terms', url: 'https://example.com/terms', selector: 'body' } }
    end

    it 'creates the document from the crawled text' do
      stub_crawler_text(new_text)

      expect { post documents_path, params: params }.to change(Document, :count).by(1)

      document = Document.last
      expect(document.text).to eq(new_text)
      expect(document.text_version).to eq(Digest::SHA256.hexdigest(new_text))
      expect(document.last_crawl_date).to be_present
      expect(flash[:notice]).to eq('Document created!')
    end

    it 'shows the crawl failure and creates nothing when the crawl fails' do
      stub_request(:post, ota_url).to_return(status: [502, 'Bad Gateway'])

      expect { post documents_path, params: params }.not_to change(Document, :count)

      expect(response.body).to include('Crawl failed: the crawler responded with HTTP 502 Bad Gateway.')
    end

    it 'does not claim success when the crawl works but the document cannot be saved' do
      stub_crawler_text(new_text)
      create(:document, service: service, url: 'https://example.com/terms', selector: 'body')

      expect { post documents_path, params: params }.not_to change(Document, :count)

      expect(response.body).to include('Document could not be saved.')
      expect(response.body).not_to include('Document created!')
    end
  end
end
