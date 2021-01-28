class PointsController < ApplicationController
  include Pundit
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include FontAwesome::Rails::IconHelper
  
  before_action :authenticate_user!, except: [:show]
  before_action :set_point, only: [:show, :edit, :update, :review, :post_review, :approve]
  before_action :set_topics, only: [:new, :create, :edit, :update, :post_review, :approve]
  before_action :check_status, only: [:create, :update]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Point

    @points = Point.includes(:service, :case, :user).order("RANDOM()").limit(100)

    if @query = params[:query]
      @points = Point.includes(:service, :case, :user).search_points_by_multiple(@query)
    end
  end

  def new
    authorize Point

    @point = Point.new
    if params[:service_id]
      @point.service_id = params[:service_id]
    end
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

    @versions = @point.versions.includes(:item).reverse()
  end

  def update
    authorize @point

    if @point.update(point_params)
      create_comment(@point.point_change)
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
      create_comment(status_badge('approved') + raw('<br>') + 'No comment given')

      redirect_to point_path(@point)
    else
      render :edit
    end
  end

  def post_review
    authorize @point

    # process a post of the review form
    if @point.update(status: point_params['status'])
	
      create_comment(status_badge(point_params['status']) + raw('<br>') + point_params['point_change'])

      redirect_to point_path(@point)
    else
      render :edit
    end
  end

  def user_points
    @points = current_user.points.includes([:service, :case])

    if @query = params[:query]
      @points = current_user.points.includes([:service, :case, :user]).search_points_by_multiple(@query)
    end
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def create_comment(comment_text)
    PointComment.create(point_id: @point.id, summary: comment_text, user_id: current_user.id)
  end

  def point_create_options(point, path)
    if point.save
      redirect_to path
      flash[:notice] = "You created a point!"
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
    params.require(:point).permit(:title, :source, :status, :analysis, :service_id, :query, :point_change, :case_id, :document, :quoteStart, :quoteEnd, :quoteText)
  end

  def check_status
    if (!['draft', 'pending', 'declined'].include? point_params['status'])
      render :edit
    end
  end
end
