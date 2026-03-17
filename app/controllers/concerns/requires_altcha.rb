# frozen_string_literal: true

module RequiresAltcha
  private

  def altcha_challenge_options
    Altcha::ChallengeOptions.new(
      hmac_key: altcha_hmac_key,
      max_number: Rails.application.config.x.altcha.max_number,
      expires: Time.current + Rails.application.config.x.altcha.challenge_expires_in.seconds
    )
  end

  def altcha_hmac_key
    Rails.application.config.x.altcha.hmac_key
  end

  def altcha_valid?
    payload = params[:altcha].presence
    payload.present? && Altcha.verify_solution(payload, altcha_hmac_key, true)
  end

  def render_altcha_failure!(view_name, resource:, set_minimum_password_length: false)
    clean_up_passwords(resource) if respond_to?(:clean_up_passwords, true)
    set_minimum_password_length if set_minimum_password_length && respond_to?(:set_minimum_password_length, true)
    message = 'Please complete the CAPTCHA challenge and try again.'
    response.set_header('Cache-Control', 'no-store')

    respond_to do |format|
      format.html do
        flash.now[:alert] = message
        render view_name, status: :unprocessable_entity
      end

      format.json do
        render json: { error: message }, status: :unprocessable_entity
      end
    end
  end
end
