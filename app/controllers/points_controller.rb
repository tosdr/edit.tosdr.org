class PointsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :must_be_creator, only: [:update]
  before_action :must_be_peer_curator, only: [:review]
  before_action :set_point, only: [:show, :edit, :update, :review]

  def index
    if params[:scope].nil? || params[:scope] == "all"
      @points = Point.includes(:service, :case, :user).all
    elsif params[:scope] == "pending"
      @points = Point.includes(:service, :case, :user).all.where(status: "pending").where.not(user_id: current_user.id)
    end
    if @query = params[:query]
      @points = Point.includes(:service, :case, :user).search_points_by_multiple(@query)
    end
  end

  def new
    @point = Point.new
    @topics = Topic.all.includes(:cases).all
    if @query = params[:service_id]
      @point['service_id'] = params[:service_id]
    end
    @service_url = @point.service ? @point.service.url : ''
  end

  def create
    #TODO: check that the point is created in either draft or pending status
    @point = Point.new(point_params)
    @topics = Topic.all.includes(:cases).all
    @point.user = current_user

    point_for_options = @point

    if params[:only_create]
      path = service_path(point_for_options.service)
      point_create_options(point_for_options, path)
    elsif params[:create_add_another]
      path = new_point_path
      point_create_options(point_for_options, path)
    end
  end

  def edit
    @service_url = @point.service.url
    @topics = Topic.all.includes(:cases).all
  end

  def show
    @comments = Comment.where(point_id: @point.id)
    @versions = @point.versions
  end

  def update
    @topics = Topic.all.includes(:cases).all
    if @point.update(point_params)
      @point.topic_id = @point.case.topic_id
      comment = create_comment(@point)
      redirect_to point_path
    elsif @point.case.nil?
      render :edit
    else
      render :edit
    end
  end

  def review
    #TODO: implement
  end

  def user_points
    @points = current_user.points.includes(:service)
    if @query = params[:query]
      @points = Point.includes(:service).search_points_by_multiple(@query)
    end
  end

  private

  def create_comment(point)
    Comment.create(point_id: point.id, summary: point.point_change, user_id: current_user.id)
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

  def point_params
    params.require(:point).permit(:title, :source, :status, :analysis, :topic_id, :service_id, :is_featured, :query, :point_change, :case_id, :document, :quoteStart, :quoteEnd, :quoteText)
  end

  def must_be_creator
    unless current_user.id == @point.id
      render :file => "public/401.html", :status => :unauthorized
    end
  end

  def must_be_peer_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
    if current_user.id == @point.id
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end
