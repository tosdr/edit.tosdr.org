require 'rails_helper'

RSpec.describe 'Service versions table', type: :request do
  # The base user factory is admin + curator, so non-admin roles are opted out explicitly.
  let(:admin) { create(:user_confirmed) }
  let(:bot) { create(:user_confirmed, admin: false, curator: false, bot: true) }

  before do
    host! 'example.com'
  end

  it 'badges each version by the user who made the change, not the service submitter' do
    service = create(:service, user: bot)
    PaperTrail.request(whodunnit: admin.id.to_s) { service.update!(name: 'Renamed by staff') }

    sign_in admin
    get service_path(service)

    rows = Nokogiri::HTML(response.body).css('.status-changes tbody tr')
    update_row = rows.find { |row| row.at_css('th')&.text == 'update' }

    expect(update_row.css('td').last.text).to include('Staff')
    expect(update_row.css('td').last.text).not_to include('Bot')
  end
end
