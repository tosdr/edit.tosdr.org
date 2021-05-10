class Api::V1::ServicesController < Api::V1::BaseController
  before_action :set_service, only: [ :show ]

  def index
    policy_scope(Service)
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
  end

  def show
  end

  private
  def set_service
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
  end
end
