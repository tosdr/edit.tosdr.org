# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User sessions', type: :request do
  before do
    host! 'example.com'
  end

  describe 'POST /users/sign_in' do
    let!(:user) { create(:user_confirmed) }

    before do
      allow(Altcha).to receive(:verify_solution).and_return(true)
    end

    it 'sets a client-readable h_key cookie for the annotation client' do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: 'Justforseedjustforseed1'
        },
        altcha: 'valid'
      }

      h_key_cookie = response.headers['Set-Cookie'].to_s.split("\n").find { |cookie| cookie.start_with?('h_key=') }

      expect(h_key_cookie).to include("h_key=#{user.h_key}")
      expect(h_key_cookie).to include('SameSite=Lax')
      expect(h_key_cookie).not_to include('HttpOnly')
    end
  end
end
