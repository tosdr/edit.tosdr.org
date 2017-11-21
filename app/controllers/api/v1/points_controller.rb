class Api::V1::PointsController < Api::V1::BaseController
  def index
    @points = policy_scope(Point)
  end
end
