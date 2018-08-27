class PointsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_point, only: [:show, :edit, :update, :review, :post_review]
  before_action :must_be_creator, only: [:update]
  before_action :must_be_peer_curator, only: [:review, :post_review]

  def index
    if params[:scope].nil? || params[:scope] == "all"
      @points = Point.includes(:service, :case, :user).order("RANDOM()").limit(100)
    elsif params[:scope] == "pending"
      @points = Point.includes(:service, :case, :user).order("RANDOM()").limit(100).where(status: "pending").where.not(user_id: current_user.id)
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
    @topics = Topic.all.includes(:cases).all
    if (point_params['status'] != 'draft' && point_params['status'] != 'pending')
      puts 'wrong update status!'
      puts point_params
      render :edit
      return
    end
    @point = Point.new(point_params)
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
    @versions = @point.versions
  end

  def update
    if (point_params['status'] != 'draft' && point_params['status'] != 'pending')
      puts 'wrong update status!'
      puts point_params
      @topics = Topic.all.includes(:cases).all
      render :edit
      return
    end
    if @point.update(point_params)
      @point.topic_id = @point.case.topic_id
      comment = create_comment(@point.point_change)
      redirect_to point_path
    elsif @point.case.nil?
      @topics = Topic.all.includes(:cases).all
      render :edit
    else
      @topics = Topic.all.includes(:cases).all
      render :edit
    end
  end

  def review
    # show the review form
  end

  def post_review
    @topics = Topic.all.includes(:cases).all
    # process a post of the review form
    if (point_params['status'] != 'approved' && point_params['status'] != 'declined')
      puts 'wrong review status!'
      puts point_params
      render :edit
      return
    end
    if @point.update(status: point_params['status'])
      comment = create_comment(point_params['status'] + ': ' + point_params['point_change'])
      if (@point.user_id != current_user.id)
        UserMailer.reviewed(@point.user, @point, current_user, point_params['status'], point_params['point_change']).deliver_now
      end
      redirect_to point_path
    else
      render :edit
    end
  end

  def user_points
    @points = current_user.points.includes(:service)
    if @query = params[:query]
      @points = Point.includes(:service).search_points_by_multiple(@query)
    end
  end

  private

  def create_comment(commentText)
    PointComment.create(point_id: @point.id, summary: commentText, user_id: current_user.id)
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
    params.require(:point).permit(:title, :source, :status, :topic_id, :service_id, :is_featured, :query, :point_change, :case_id, :document, :quoteStart, :quoteEnd, :quoteText)
  end

  def must_be_creator
    unless current_user.id == @point.user_id
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
