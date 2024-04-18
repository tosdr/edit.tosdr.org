# frozen_string_literal: true

# app/controllers/services_controller.rb
class ServicesController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!, except: %i[index show]
  invisible_captcha only: %i[create update], honeypot: :description

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Service

    @q = Service.ransack(params[:q])
    @services = @q.result(distinct: true).page(params[:page] || 1)
  end

  def new
    authorize Service

    return user_not_authorized unless current_user && privileged_user

    @service = Service.new
  end

  def create
    authorize Service

    return user_not_authorized unless current_user && privileged_user

    @service = Service.new(service_params)
    @service.user = current_user

    if @service.save
      uploader = LogoUploaderController.new(@service.id)
      logo = params[:service][:logo]
      if logo
        handle_logo(uploader, logo, @service)
      else
        flash[:notice] = 'The service has been created!'
        redirect_to service_path(@service)
      end
    else
      render :new
    end
  end

  def annotate
    authorize Service

    @service = Service.includes(documents: [:points, :user, :document_type]).find(params[:id] || params[:service_id])
    @documents = @service.documents
    @sourced_from_ota = @documents.where(ota_sourced: true).any?
    if params[:point_id] && current_user
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

    if params[:point_id] && current_user
      point = Point.find_by id: params[:point_id]
    else
      @case = Case.find(params[:quoteCaseId])
      point = build_point(@case, @service, current_user)
    end

    point = build_quote(point)

    status = point.status
    point.status = status == 'approved-not-found' ? 'approved' : 'pending'

    if point.save
      if params[:point_id]
        redirect_to point_path(params[:point_id])
      else
        redirect_to service_path(params[:id]) + '/annotate'
      end
    else
      puts point.errors.full_messages
    end
  end

  def show
    @service = Service.includes(points: [:case, :user]).find(params[:id] || params[:service_id])

    authorize @service

    @sourced_from_ota = @service.documents.where(ota_sourced: true).any?
    @points = @service.points.where(status: 'approved') unless current_user
    @points = @service.points_ordered_status_class.values.flatten if current_user
    @versions = @service.versions.includes(:item).reverse
  end

  def edit
    @service = Service.find(params[:id] || params[:service_id])

    authorize @service
  end

  def update
    uploader = LogoUploaderController.new(params[:id] || params[:service_id])
    @service = Service.find(params[:id] || params[:service_id])

    authorize @service

    if @service.update(service_params)
      logo = params[:service][:logo]
      if logo
        if uploader.store!(logo)
          flash[:notice] = 'Uploaded logo!'
          redirect_to service_path(@service)
        else
          flash[:alert] = 'Uploading the logo failed!'
          render :edit
        end
      else
        flash[:notice] = 'The service has been updated!'
        redirect_to service_path(@service)
      end
    else
      flash[:alert] = 'Failed to update the service!'
      render :edit
    end
  end

  def destroy
    @service = Service.find(params[:id] || params[:service_id])

    authorize @service

    if @service.points.any?
      flash[:alert] = 'Users have contributed valuable insight to this service!'
      redirect_to service_path(@service)
    else
      @service.destroy
      flash[:notice] = 'Service has been removed!'
      redirect_to services_path
    end
  end

  private

  def handle_logo(uploader, logo, service)
    puts 'Uploaded image'
    if uploader.store!(logo)
      flash[:notice] = 'Created service with logo!'
    else
      flash[:alert] = 'Uploading the logo failed!'
    end
    redirect_to service_path(service)
  end

  def build_quote(point)
    document = Document.find(params[:document_id])
    point.document = document

    point.quote_text = document.text[params[:quote_start].to_i, params[:quote_end].to_i - params[:quote_start].to_i]
    point.source = document.url
    point.quote_start = params[:quote_start]
    point.quote_end = params[:quote_end]
    point
  end

  def build_point(case_obj, service, current_user)
    point = Point.new(
      params.permit(:title, :source, :status, :analysis, :service_id, :query, :point_change, :case_id, :document, :quote_start, :quote_end, :quote_text)
    )
    point.user = current_user
    point.case = case_obj
    point.title = case_obj.title
    point.service = service
    point.analysis = 'Generated through the annotate view'
    point
  end

  def privileged_user
    current_user.admin? || current_user.curator? || current_user.bot?
  end

  def service_params
    if current_user.curator?
      params.require(:service).permit(:name, :url, :query, :wikipedia, :is_comprehensively_reviewed)
    else
      params.require(:service).permit(:name, :url, :query, :wikipedia)
    end
  end
end
