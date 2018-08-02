class ServicesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_curator, only: [:destroy]

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
    @service = Service.find(params[:id] || params[:service_id])
    @topics = Topic.all.includes(:cases).all
    @documents = @service.documents
  end

  def quote
    puts 'quote!'
    puts params
    @service = Service.find(params[:id] || params[:service_id])
    @case = Case.find(params[:quoteCaseId])
    point = Point.new(
      params.permit(:title, :source, :status, :analysis, :topic_id, :service_id, :is_featured, :query, :point_change, :case_id, :document, :quoteStart, :quoteEnd, :quoteText)
    )
    document = Document.find(params[:document_id])
    puts 'Found document'
    point.quoteText = document.text[params[:quoteStart].to_i, params[:quoteEnd].to_i - params[:quoteStart].to_i]
    point.user = current_user
    point.case = @case
    point.title = @case.title
    point.status = 'pending'
    point.service = @service
    point.source = document.url
    point.analysis = 'Generated through the annotate view'
    point.document = document
    if (point.save(
      quoteRev: params[:quoteRev],
      quoteStart: params[:quoteStart],
      quoteEnd: params[:quoteEnd]
    ))
      redirect_to service_path(params[:id]) + '/annotate'
    else
      puts point.errors.full_messages
    end
  end

  def show
    @service = Service.includes(points: [:case], versions: [:item]).find(params[:id] || params[:service_id])
    if current_user
      case params[:scope]
      when nil
        @points = @service.points
      when 'pending'
        @points = @service.points.where(status: 'pending').where.not(user_id: current_user.id)
      when 'archived-versions'
        @versions = @service.versions
      end
    else
      @points = @service.points.where(status: 'approved')
    end

    @versions = @service.versions

    if @query = params[:topic]
      @points = @points.where(topic_id: params[:topic][:id])
    end
  end

  def edit
    @service = Service.find(params[:id] || params[:service_id])
  end

  def update
    @service = Service.find(params[:id] || params[:service_id])
    @service.update(service_params)
    redirect_to service_path(@service)
  end

  def destroy
    @service = Service.find(params[:id] || params[:service_id])
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

  def service_params
    params.require(:service).permit(:name, :url, :query, :wikipedia, :is_comprehensively_reviewed)
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end
