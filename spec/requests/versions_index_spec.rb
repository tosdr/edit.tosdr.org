require 'rails_helper'

RSpec.describe 'Recent changes (versions index)', type: :request do
  # The base user factory is admin + curator, so non-admin roles are opted out explicitly.
  let(:admin) { create(:user_confirmed) }
  let(:bot) { create(:user_confirmed, admin: false, curator: false, bot: true) }

  before do
    host! 'example.com'
  end

  it 'badges each version by the user who made the change, not the item author' do
    point = create(:point, user: bot, status: 'pending')
    PaperTrail.request(whodunnit: admin.id.to_s) { point.update!(title: 'Edited by staff') }

    sign_in admin
    get versions_path

    panels = Nokogiri::HTML(response.body).css('#accordion > .panel')
    update_panel = panels.find { |panel| panel.text.include?('updated') }

    expect(update_panel.text).to include('Staff')
    expect(update_panel.text).not_to include('Bot')
  end
end
