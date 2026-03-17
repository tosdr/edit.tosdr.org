# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ALTCHA auth protection', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  before do
    host! 'example.com'
  end

  describe 'GET /altcha' do
    it 'returns a challenge payload for the widget' do
      get '/altcha'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json).to include('algorithm', 'challenge', 'salt', 'signature')
      expect(json['maxnumber']).to eq(Rails.application.config.x.altcha.max_number)
    end
  end

  describe 'POST /users/sign_in' do
    let!(:user) { create(:user_confirmed) }

    before do
      allow(Altcha).to receive(:verify_solution).and_return(false)
    end

    it 'rejects logins without a valid altcha solution' do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: 'Justforseedjustforseed1'
        },
        altcha: 'invalid'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Please complete the CAPTCHA challenge and try again.')
    end

    it 'returns a JSON error for JSON sign-in requests with an invalid altcha solution' do
      post user_session_path(format: :json), params: {
        user: {
          email: user.email,
          password: 'Justforseedjustforseed1'
        },
        altcha: 'invalid'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)).to eq(
        'error' => 'Please complete the CAPTCHA challenge and try again.'
      )
    end
  end

  describe 'POST /users' do
    before do
      allow(Altcha).to receive(:verify_solution).and_return(false)
    end

    it 'blocks sign up when the altcha payload is invalid' do
      get new_user_registration_path
      spinner = Nokogiri::HTML(response.body).at_css('input[name="spinner"]')&.[]('value')

      travel InvisibleCaptcha.timestamp_threshold.seconds + 1.second do
        expect do
          post user_registration_path, params: {
            user: {
              email: 'new-user@example.com',
              username: 'new_user',
              password: 'Password123',
              password_confirmation: 'Password123'
            },
            altcha: 'invalid',
            spinner: spinner
          }
        end.not_to change(User, :count)
      end

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Please complete the CAPTCHA challenge and try again.')
    end
  end

  describe 'POST /users/password' do
    let!(:user) { create(:user_confirmed) }

    before do
      allow(Altcha).to receive(:verify_solution).and_return(false)
    end

    it 'blocks password reset requests without a valid altcha solution' do
      expect do
        post user_password_path, params: {
          user: {
            email: user.email
          },
          altcha: 'invalid'
        }
      end.not_to change { user.reload.reset_password_token }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Please complete the CAPTCHA challenge and try again.')
    end
  end
end
