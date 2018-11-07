class ServicesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_curator, only: [:destroy]

  def index
    @services = Service.includes(points: [:case]).all
    @document_counts = Document.group(:service_id).count
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
      redirect_to service_path(@service)
    else
      render :new
    end
  end

  def annotate
    @service = Service.includes(documents: [:points]).find(params[:id] || params[:service_id])
    @documents = @service.documents
    if (params[:point_id] && current_user)
      @point = Point.find_by id: params[:point_id], user_id: current_user.id
    else
      @topics = Topic.all.includes(:cases).all
    end
  end

  def quote
    puts 'quote!'
    puts params
    @service = Service.find(params[:id] || params[:service_id])
    if (params[:point_id] && current_user)
      point = Point.find_by id: params[:point_id], user_id: current_user.id
    else
      @case = Case.find(params[:quoteCaseId])
      point = Point.new(
        params.permit(:title, :source, :status, :analysis, :topic_id, :service_id, :query, :point_change, :case_id, :document, :quoteStart, :quoteEnd, :quoteText)
      )
      point.user = current_user
      point.case = @case
      point.title = @case.title
      point.service = @service
      point.analysis = 'Generated through the annotate view'
    end
    document = Document.find(params[:document_id])
    point.document = document
    point.quoteText = document.text[params[:quoteStart].to_i, params[:quoteEnd].to_i - params[:quoteStart].to_i]
    point.source = document.url
    point.quoteStart = params[:quoteStart]
    point.quoteEnd = params[:quoteEnd]
    point.status = 'pending'
    if (point.save)
      if (params[:point_id])
        redirect_to point_path(params[:point_id])
      else
        redirect_to service_path(params[:id]) + '/annotate'
      end
    else
      puts point.errors.full_messages
    end
  end

  def show
    @service = Service.includes(points: [:case, :user], versions: [:item]).find(params[:id] || params[:service_id])
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
    if current_user.curator? then
      params.require(:service).permit(:name, :url, :query, :wikipedia, :is_comprehensively_reviewed)
    else
      params.require(:service).permit(:name, :url, :query, :wikipedia)
    end
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end
