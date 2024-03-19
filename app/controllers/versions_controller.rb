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
end
