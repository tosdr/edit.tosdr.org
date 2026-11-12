require 'rails_helper'

RSpec.describe 'Point versions table', type: :request do
  # The base user factory is admin + curator, so non-admin roles are opted out explicitly.
  let(:admin) { create(:user_confirmed) }
  let(:bot) { create(:user_confirmed, admin: false, curator: false, bot: true) }

  before do
    host! 'example.com'
  end

  it 'badges each version by the user who made the change, not the point author' do
    point = create(:point, user: bot, status: 'pending')
    PaperTrail.request(whodunnit: bot.id.to_s) { point.update!(title: 'Edited by the bot') }
    PaperTrail.request(whodunnit: admin.id.to_s) { point.update!(title: 'Edited by staff') }

    sign_in admin
    get point_path(point)

    headings = Nokogiri::HTML(response.body).css('#accordion .panel-heading').map(&:text)
    staff_heading = headings.find { |h| h.include?('Version 3:') }
    bot_heading = headings.find { |h| h.include?('Version 2:') }

    expect(staff_heading).to include('Staff')
    expect(staff_heading).not_to include('Bot')
    expect(bot_heading).to include('Bot')
  end
end
