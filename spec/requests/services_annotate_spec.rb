require 'rails_helper'

RSpec.describe 'Services annotate page', type: :request do
  it 'renders each document with highlights for quotes at their stored offsets' do
    host! 'example.com'
    sign_in create(:user_confirmed)
    text = 'Intro. We collect your data and keep it.'
    quote = 'We collect your data'
    document = create(:document, text: text)
    create(:point, document: document, service: document.service, status: 'approved', quote_text: quote,
                   quote_start: text.index(quote), quote_end: text.index(quote) + quote.length)

    get annotate_path(document.service)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<hypothesis-highlight class=\"hypothesis-highlight user-annotations\"> #{quote}")
    expect(response.body).not_to include('Restore quotes')
    expect(response.body).not_to include('caseToast')
    expect(response.body).not_to include('data-content')
    expect(response.body).to include("data-document-id=\"#{document.id}\"")
  end

  # Points are created from the Hypothesis sidebar (POST /api/v1/points). The old in-page
  # annotate form that posted offsets here is retired.
  it 'no longer accepts the legacy annotate form' do
    host! 'example.com'
    sign_in create(:user_confirmed)
    document = create(:document, text: 'Example policy text.')

    expect do
      post "/services/#{document.service_id}/annotate",
           params: { quoteCaseId: create(:case).id, document_id: document.id, quote_start: 0, quote_end: 7 }
    end.not_to change(Point, :count)

    expect(response).to have_http_status(:not_found)
  end
end
