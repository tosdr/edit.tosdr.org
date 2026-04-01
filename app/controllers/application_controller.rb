# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include ApplicationHelper
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::InvalidCrossOriginRequest, with: :cross_origin_request
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token


  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: :not_found

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit

  add_flash_types :info, :error, :warning

  def configure_permitted_parameters
    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def authenticate_admin!
    response.headers['Cache-Control'] = 'no-store'
    redirect_to root_path unless current_user&.admin
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end

  def not_found
    respond_to do |format|
      format.html { render plain: "404 Not Found", status: 404 }
      format.json { render json: { error: 'Not found' }, status: 404 }
      format.js   { render plain: "404 Not Found", status: 404, content_type: 'text/plain' }
      format.any  { head 404 }
    end
  end

  def cross_origin_request
    render plain: "404 Not Found", status: 404, content_type: 'text/plain'
  end

  def invalid_authenticity_token
    # Expired sessions and unsolicited bot POSTs can trigger this.
    # Reset the session and return a controlled response without stack traces.
    reset_session

    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Your session expired. Please try again.' }
      format.json { render json: { error: 'Invalid authenticity token' }, status: :unprocessable_entity }
      format.js   { head :unprocessable_entity }
      format.any  { head :unprocessable_entity }
    end
  end
end
