require 'rails_helper'

RSpec.describe 'User registrations', type: :request do
  it 'redirects instead of raising when hard_delete fails' do
    host! 'example.com'
    user = FactoryBot.create(:user_confirmed)
    sign_in user
    allow_any_instance_of(User).to receive(:hard_delete).and_return(false)

    delete user_registration_path

    expect(response).to redirect_to(edit_user_registration_path)
    expect(flash[:alert]).to eq('Something is wrong, please contact the team...')
  end

  it 'only invokes hard_delete once during account deletion' do
    host! 'example.com'
    user = FactoryBot.create(:user_confirmed)
    sign_in user
    calls = 0
    allow_any_instance_of(User).to receive(:hard_delete) do
      calls += 1
      true
    end

    delete user_registration_path

    expect(calls).to eq(1)
  end
end
