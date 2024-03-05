# frozen_string_literal: true

# app/controllers/versions_controller.rb
class VersionsController < ApplicationController
  include Pundit::Authorization
  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    versions = Version.order('created_at DESC').limit(50)
    @versions = versions.includes(:item)
  end
  
  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
