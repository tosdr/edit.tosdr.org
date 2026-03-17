# frozen_string_literal: true

altcha_hmac_key = ENV['ALTCHA_HMAC_KEY'].presence ||
                  Rails.application.credentials.dig(:altcha, :hmac_key).presence ||
                  ENV['SECRET_KEY_BASE'].presence

if altcha_hmac_key.blank?
  if Rails.env.production?
    raise 'Set ALTCHA_HMAC_KEY or credentials.altcha[:hmac_key] before enabling ALTCHA in production.'
  end

  altcha_hmac_key = 'development-altcha-hmac-key-change-me'
end

Rails.application.config.x.altcha.hmac_key = altcha_hmac_key
Rails.application.config.x.altcha.challenge_expires_in = ENV.fetch('ALTCHA_CHALLENGE_EXPIRES_IN', 10.minutes.to_i).to_i
Rails.application.config.x.altcha.max_number = ENV.fetch('ALTCHA_MAX_NUMBER', 1_000_000).to_i
