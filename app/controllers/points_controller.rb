# frozen_string_literal: true

# app/controllers/points_controller.rb
class PointsController < ApplicationController
  include Pundit::Authorization
  include ActionView::Helpers::TagHelper
  include FontAwesome5::Rails::IconHelper

  before_action :authenticate_user!, except: [:show]
  before_action :set_point, only: %i[show edit update review post_review approve decline]
  before_action :set_topics, only: %i[new edit]
  before_action :set_services, only: %i[new edit]
  before_action :check_status, only: %i[create update]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Point
    @q = Point.eager_loaded.ransack(params[:q])
    @points = @q.result(distinct: true).page(params[:page] || 1)
  end

  def user_points
    authorize Point
    @q = Point.eager_loaded.current_user_points(current_user).ransack(params[:q])
    @points = @q.result(distinct: true).page(params[:page] || 1)
  end

  def list_docbot
    @docbot_points = User.docbot_user.present? ? Point.docbot : []
    @q = @docbot_points.any? ? @docbot_points.ransack(params[:q]) : []
    @docbot_points = @q.any? ? @q.result(distinct: true).page(params[:page] || 1) : []
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

    @can_edit_docbot_point = false
    docbot = User.docbot_user
    @can_edit_docbot_point = true if docbot && @point.user_id == docbot.id && current_user.curator?
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

    docbot = User.docbot_user
    @point.user_id = current_user.id if docbot && @point.user_id == docbot.id && current_user.curator?
    if @point.update(point_params)
      annotation.save! if annotation
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

  def post_review
    authorize @point

    # process a post of the review form
    invalid_status = point_params['status'] != 'approved' && point_params['status'] != 'declined' && point_params['status'] != 'changes-requested'
    return if invalid_status

    if @point.update(status: point_params['status'])
      comment = point_params['status'] + ': ' + point_params['point_change']
      create_comment(comment)

      if @point.user_id != current_user.id
        UserMailer.reviewed(@point.user, @point, current_user, point_params['status'],
                            point_params['point_change']).deliver_now
      end

      redirect_to point_path(@point)
    else
      render :review
    end
  end

  def approve
    authorize @point

    if @point.update(status: 'approved')
      comment = status_badge('approved') + raw('<br>') + 'No comment given'
      create_comment(comment)

      if params['source'] == 'docbot'
        redirect_to request.referrer
      else
        redirect_to point_path(@point)
      end
    else
      render :edit
    end
  end

  def decline
    authorize @point

    if @point.update(status: 'declined')
      comment = status_badge('declined') + raw('<br>') + 'No comment given'
      create_comment(comment)

      if params['source'] == 'docbot'
        redirect_to list_docbot_path
      else
        redirect_to point_path(@point)
      end
    else
      render :edit
    end
  end

  private

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

  def set_services
    @services = Service.order('name ASC')
  end

  def point_params
    params.require(:point).permit(:title, :source, :status, :analysis, :service_id, :query, :point_change, :case_id,
                                  :document, :source)
  end

  def check_status
    render :edit unless %w[draft pending declined].include? point_params['status']
  end
end
