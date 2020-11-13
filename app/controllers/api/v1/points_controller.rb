class Api::V1::PointsController < Api::V1::BaseController
  before_action :set_point, only: [ :show ]

  def index
    policy_scope(Point)

    if params[:page]
      @points = Point.page(params[:page]).per(100)
      page_count = @points.total_pages
    else
      @points = Point.order('updated_at DESC')
      page_count = 1
    end

    render json: { points: @points, meta: { total_pages: page_count, total_records: Point.count } }
  end

  def show
  end

  private

  def set_point
    @point = Point.find(params[:id])
    authorize @point
  end
end
