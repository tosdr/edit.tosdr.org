class Api::V1::PointsController < Api::V1::BaseController
  before_action :set_point, only: [ :show ]

  def index
    policy_scope(Point)
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
  end

  def show
  end

  private

  def set_point
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
  end
end
