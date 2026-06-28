require 'rails_helper'

# End-to-end coverage for the crawl path: crawl -> analyze_points -> handle_missing_points.
# Guards two controller regressions that used to 500 (or mangle the flash) on every crawl
# of a document that had points and whose text changed:
#   * analyze_points referenced an undefined `document` instead of `@document`
#   * the success message used backticks (shell execution) instead of a string
RSpec.describe 'Document crawl', type: :request do
  let(:ota_url) { 'http://ota.example.test/fetch' }
  let(:old_text) { 'Old policy: we collect your data and keep it forever.' }
  let(:new_text) { 'Brand new policy with completely rewritten wording.' }

  before do
    host! 'example.com'
    ENV['OTA_URL'] = ota_url
    ENV['OTA_API_SECRET'] = 'test-secret'
    # The OTA crawler returns the fetched document text as a JSON string.
    stub_request(:post, ota_url)
      .to_return(status: 200, body: new_text.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    sign_in create(:user_confirmed)
  end

  after do
    ENV.delete('OTA_URL')
    ENV.delete('OTA_API_SECRET')
  end

  it 'crawls, flags points missing from the new text, and reports the count' do
    document = create(:document, text: old_text)
    quote = 'we collect your data'
    point = create(:point, document: document, service: document.service,
                           status: 'approved', quote_text: quote,
                           quote_start: old_text.index(quote),
                           quote_end: old_text.index(quote) + quote.length)

    post document_crawl_path(document)

    expect(response).to redirect_to(document_path(document))
    expect(document.reload.text).to eq(new_text)
    expect(point.reload.status).to eq('approved-not-found')
    expect(flash[:notice]).to include('There are 1 points missing from the new text')
  end
end
