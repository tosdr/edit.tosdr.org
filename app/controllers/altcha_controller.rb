# frozen_string_literal: true

class AltchaController < ApplicationController
  include RequiresAltcha

  def show
    response.set_header('Cache-Control', 'no-store')
    render json: Altcha.create_challenge(altcha_challenge_options)
  end
end
