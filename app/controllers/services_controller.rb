class ServicesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_service, only: [:show, :edit, :update, :destroy]

  def index
    @services = Service.all
    if @query = params[:query]
      @services = Service.search_by_name(@query)
    end
  end

  def new
    @service = Service.new
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to services_path
    else
      render :new
    end
  end

  def show
    if current_user
      case params[:scope]
      when nil
        @points = @service.points
      when 'pending'
        @points = @service.points.where(status: 'pending')
      when 'archived-versions'
        @versions = @service.versions
      end
    else
      @points = @service.points.where(status: 'approved')
    end

    @rating = @service.rating_for_view

    @versions = @service.versions

    if @query = params[:topic]
      @points = @points.where(topic_id: params[:topic][:id])
    end
  end

  def edit
  end

  def update
    @service.update(service_params)
    redirect_to service_path(@service)
  end

  def destroy
    if @service.points.any?
      flash[:alert] = "Users have contributed valuable insight to this service!"
      redirect_to service_path(@service)
    else
      @service.destroy
      flash[:notice] = "Service has been removed!"
      redirect_to services_path
    end
  end

  private

  def set_service
    @service = Service.find(params[:id] || params[:service_id])
  end

  def service_params
    params.require(:service).permit(:name, :url, :query)
  end

end
