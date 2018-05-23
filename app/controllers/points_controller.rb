class PointsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_curator, only: [:edit, :featured, :destroy]
  before_action :set_point, only: [:show, :edit, :featured, :update, :destroy]
  before_action :points_get, only: [:index]

  def index
    if @query = params[:query]
      @points = Point.includes(:service).search_points_by_multiple(@query)
    end
  end

  def new
    @point = Point.new
    @services = Service.all
    @topics = Topic.all
  end

  def create
    @point = Point.new(point_params)
    @point.user = current_user
    if params[:only_create]
      if @point.save
        redirect_to points_path
        flash[:notice] = "You created a point!"
      else
        render :new
      end
    elsif params[:create_add_another]
      if @point.save
        redirect_to new_point_path
        flash[:notice] = "You created a point! Feel free to add another."
      else
        render :new
      end
    end
  end

  def edit
  end

  def show
    @point
    puts @point.id
    @comments = Comment.where(point_id: @point.id)
    @versions = @point.versions
    @reasons = @point.reasons
  end

  def update
    puts point_params
    @point.update(point_params)
    if @point.errors.details.any?
      puts @point.errors.messages
      render :edit
    else
      flash[:notice] = "Point successfully updated!"
      redirect_to point_path(@point)
    end
  end

  def destroy
    @point.destroy
    flash[:notice] = "Point successfully deleted!"
    redirect_to points_path
  end

  def featured
    if !@point.is_featured? && @point.status == "approved"
      if @point.service.points.reject { |p| !p.is_featured }.count < 5
        @point.update(is_featured: !@point.is_featured)
        redirect_to point_path(@point)
      else
        flash[:alert] = "There are already five featured points for this service!"
        redirect_to point_path(@point)
      end
    elsif @point.is_featured?
      @point.update(is_featured: !@point.is_featured)
      redirect_to point_path(@point)
    end
  end

  def user_points
    @points = current_user.points.includes(:service)
    if @query = params[:query]
      @points = Point.includes(:service).search_points_by_multiple(@query)
    end
  end

  private

  def set_point
    @point = Point.find(params[:id])
  end

  def set_service
    @service = Service.find(params[:service_id])
  end

  def point_params
    params.require(:point).permit(:title, :source, :status, :rating, :analysis, :topic_id, :service_id, :is_featured, :query, :point_change)
  end

  def points_get
    if params[:scope].nil? || params[:scope] == "all"
      @points = Point.includes(:service).all
    elsif params[:scope] == "pending"
      @points = Point.includes(:service).all.where(status: "pending")
    end
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end

