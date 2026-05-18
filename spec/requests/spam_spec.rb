require 'rails_helper'

RSpec.describe 'Spam', type: :request do
  it 'rejects unsupported spammable types without creating spam' do
    host! 'example.com'
    user = FactoryBot.create(:user_confirmed)
    sign_in user

    document = FactoryBot.create(:document)

    expect do
      get flag_as_spam_path, params: { spammable_type: 'Document', spammable_id: document.id }
    end.not_to change(Spam, :count)
    expect(response).to have_http_status(:not_found)
  end
end
