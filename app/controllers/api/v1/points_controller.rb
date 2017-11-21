class Api::V1::PointsController < Api::V1::BaseController
  before_action set_point, only: [ :show ]
  def index
    @points = policy_scope(Point)
  end

  def show
  end

  private
  def set_point
    @point = Point.find(params[:id])
    authorize @point
  end
end
