class Api::V1::ServicesController < Api::V1::BaseController
  before_action :set_service, only: [ :show ]

  def index
    policy_scope(Service)
    @services = Service.all
  end

  def show
  end

  private
  def set_service
    @service = Service.find(params[:id])
    authorize @service
  end
end
