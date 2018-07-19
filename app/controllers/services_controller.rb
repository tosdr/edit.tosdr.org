class ServicesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_curator, only: [:destroy]
  before_action :set_service, only: [:show, :edit, :annotate, :update, :destroy]

  def index
    @services = Service.includes(points: [:case]).all
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

  def annotate
    @points = @service.points.where('"status" in (\'approved\', \'pending\')')
    # @docRevisions = @service.doc_revisions
    @docRevisions = DocRevision.where('service_id = '+@service.id.to_s) #FIXME
    puts @docRevisions
  end

  def quote
    puts 'quote!'
    puts params
    point = Point.find(params[:quotePointId])
    point.update(
      quoteDoc: params[:quoteDoc],
      quoteRev: params[:quoteRev],
      quoteStart: params[:quoteStart],
      quoteEnd: params[:quoteEnd]
    )
    point.save
    redirect_to service_path(params[:id]) + '/annotate'
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

    @versions = @service.versions

    if params[:topic]
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
    @service = Service.includes(points: [:case]).find(params[:id] || params[:service_id])
  end

  def service_params
    params.require(:service).permit(:name, :url, :query, :wikipedia, :is_comprehensively_reviewed)
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end
