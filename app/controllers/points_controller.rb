class PointsController < ApplicationController
  include Pundit::Authorization
  include ActionView::Helpers::TagHelper
  include FontAwesome5::Rails::IconHelper

  before_action :authenticate_user!, except: [:show]
  before_action :set_point, only: %i[show edit update review approve]
  before_action :set_topics, only: %i[new create edit update approve]
  before_action :check_status, only: %i[create update]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Point
    @q = Point.includes([:case, :service, :user]).ransack(params[:q])
    @points = @q.result(distinct: true).page(params[:page] || 1)
  end

  def new
    authorize Point

    @point = Point.new
    @point.service_id = params[:service_id] if params[:service_id]
  end

  def create
    authorize Point

    @point = Point.new(point_params)
    @point.user = current_user

    point_for_options = @point

    if params[:only_create]
      path = service_path(point_for_options.service)
      point_create_options(point_for_options, path)
    elsif params[:create_add_another]
      path = new_service_point_path(point_for_options.service)
      point_create_options(point_for_options, path)
    end
  end

  def edit
    authorize @point
  end

  def show
    authorize @point
    # to-do : error handling
    @point_text = @point.quote_text
    if @point.annotation_ref
      annotation = Point.retrieve_annotation(@point.annotation_ref)
      annotation_json = JSON.parse(annotation['target_selectors'])
      @point_text = annotation_json[2] && annotation_json[2]['exact']
    end
    @versions = @point.versions.includes(:item).reverse
  end

  def update
    authorize @point

    if (point_params[:case_id] != @point.case_id) && @point.annotation_ref
      case_obj = Case.find(point_params[:case_id])
      uuid = StringConverter.new(string: @point.annotation_ref).to_uuid
      annotation = Annotation.find(uuid)
      annotation.tags = [] << case_obj.title
    end

    if @point.update(point_params)
      annotation.save!
      comment = @point.point_change.present? ? @point.point_change : 'point updated without comment'
      create_comment(comment)
      redirect_to point_path(@point)
    elsif @point.case.nil?
      render :edit
    else
      render :edit
    end
  end

  def review
    authorize @point
  end

  def approve
    authorize @point

    if @point.update(status: 'approved')
      comment = status_badge('approved') + raw('<br>') + 'No comment given'
      create_comment(comment)
      redirect_to point_path(@point)
    else
      render :edit
    end
  end

  private

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end

  def create_comment(comment_text)
    PointComment.create!(point_id: @point.id, summary: comment_text, user_id: current_user.id)
  end

  def point_create_options(point, path)
    if point.save
      redirect_to path
      flash[:notice] = 'Point created'
    elsif point.case.nil?
      render :new
    else
      render :new
    end
  end

  def set_point
    @point = Point.find(params[:id])
  end

  def set_topics
    @topics = Topic.all.includes(:cases).all
  end

  def point_params
    params.require(:point).permit(:title, :source, :status, :analysis, :service_id, :query, :point_change, :case_id, :document)
  end

  def check_status
    unless %w[draft pending declined].include? point_params['status']
      render :edit
    end
  end
end
