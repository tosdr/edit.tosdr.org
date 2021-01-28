class ServicesController < ApplicationController
  include Pundit

  before_action :authenticate_user!, except: [:index, :show]

  invisible_captcha only: [:create, :update], honeypot: :description

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Service
  end

  def list_all
    authorize Service

    object = []
    services = Service.all
    services.map do |service|
    # This takes way too long:
    #   object << { pending_points_count: service.pending_points.count, documents_count: service.documents.count, service: service }
      object << { service: service }
    end

    respond_to do |format|
      format.json { render json: object }
    end
  end

  def new
    authorize Service
	
	if current_user && (current_user.admin? || current_user.curator? || current_user.bot?)
		@service = Service.new
	else
		user_not_authorized
	end
  end

  def create
    authorize Service

	if current_user && (current_user.admin? || current_user.curator? || current_user.bot?)

		@service = Service.new(service_params)
		@service.user = current_user

		if @service.save
		  redirect_to service_path(@service)
		else
		  render :new
		end
	else
		user_not_authorized
	end
  end

  def annotate
    authorize Service

    @service = Service.includes(documents: [:points]).find(params[:id] || params[:service_id])
    @documents = @service.documents
    if (params[:point_id] && current_user)
      @point = Point.find_by id: params[:point_id]
    else
      @topics = Topic.topic_use_frequency
    end
  end

  def quote
    authorize Service

    puts 'quote!'
    puts params
    @service = Service.find(params[:id] || params[:service_id])
    if (params[:point_id] && current_user)
      point = Point.find_by id: params[:point_id]
    else
      @case = Case.find(params[:quoteCaseId])
      point = Point.new(
        params.permit(:title, :source, :status, :analysis, :service_id, :query, :point_change, :case_id, :document, :quoteStart, :quoteEnd, :quoteText)
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
    if (point.status === 'approved-not-found')
      point.status = 'approved'
    else
      point.status = 'pending'
    end
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
    authorize @service

    if current_user
      @points = @service.points_ordered_status_class.values.flatten
    else
      @points = @service.points.where(status: 'approved')
    end

    @versions = @service.versions
  end

  def edit
    @service = Service.find(params[:id] || params[:service_id])

    authorize @service
  end

  def update
    @service = Service.find(params[:id] || params[:service_id])

    authorize @service
    if @service.update(service_params)
      redirect_to service_path(@service)
    else
      render :edit
    end
  end

  def destroy
    @service = Service.find(params[:id] || params[:service_id])

    authorize @service

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

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def service_params
    if current_user.curator?
      params.require(:service).permit(:name, :url, :query, :wikipedia, :is_comprehensively_reviewed)
    else
      params.require(:service).permit(:name, :url, :query, :wikipedia)
    end
  end
end
