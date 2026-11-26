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
  end
end
