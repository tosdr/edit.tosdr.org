class Api::V1::ServicesController < Api::V1::BaseController
  before_action :set_service, only: [ :show ]

  def index
    policy_scope(Service)

    if params[:page]
      @services = Service.page(params[:page]).per(100)
      page_count = @services.total_pages
    else
      @services = Service.order('updated_at DESC')
      page_count = 1
    end

    render json: { services: @services, meta: { total_pages: page_count, total_records: Service.count } }
  end

  def show
  end

  private
  def set_service
    @service = Service.find(params[:id])
    authorize @service
  end
end
