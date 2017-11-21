class Api::V1::ServicesController < Api::V1::BaseController
  before_action :set_service, only: [ :show ]

  def index
    @services = policy_scope(Service)
  end

  def show
  end

  private
  def set_service
    @service = Service.find(params[:id])
    authorize @service
  end
end
