class Api::V1::PointsController < Api::V1::BaseController
  before_action :set_point, only: [ :show ]
  def index
    policy_scope(Point)
    @points = Point.all
  end

  def show
  end

  private
  def set_point
    @point = Point.find(params[:id])
    authorize @point
  end
end
