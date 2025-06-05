# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include ApplicationHelper
  rescue_from ActiveRecord::RecordNotFound, with: :not_found


  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit

  add_flash_types :info, :error, :warning

  def configure_permitted_parameters
    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end

  def not_found
    respond_to do |format|
      format.html { render plain: "404 Not Found", status: 404 }
      format.json { render json: { error: 'Not found' }, status: 404 }
      format.any  { head 404 }
    end
  end
end
