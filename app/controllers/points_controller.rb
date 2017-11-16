class PointsController < ApplicationController
  before_action :set_point, only: [:show, :edit, :update, :destroy]
  before_action :set_point_by_point_id, only: [:featured]
  # before_action :set_service
  # before_action :set_topic

  def index
    @points = Point.all
  end

  def new
    @point = Point.new
    @services = Service.all
    @topics = Topic.all
    # if current_user
    #   @point = Point.new
    # else
    #   flash[:notice] = "Please log in before adding a point"
    #   redirect_to new_user_path
    # end
  end

  def create
    @point = Point.new(point_params)
    @point.user = current_user
    # need to instantiate the services ?
    # @point.topic = @topic
    # @point.service = @service
    # if yes, TODO: create the setting private methods
    if @point.save
      flash[:notice] = "You created a point!"
      redirect_to points_path
    else
      redirect_to new_point_path
    end
  end

  def edit
  end

  def show
  end

  def update
    @point.update(point_params)
    flash[:notice] = "Point successfully updated!"
    redirect_to point_path(@point)
  end

  def destroy
    @point.destroy
    redirect_to points_path
  end

  def featured
    if !@point.is_featured? && @point.status == "approved"
      if @point.service.points.reject { |p| !p.is_featured }.count < 5
        @point.update(is_featured: !@point.is_featured)
      else
        flash[:alert] = "There are already five featured points!"
        redirect_to point_path(@point)
      end
    elsif @point.is_featured?
      @point.update(is_featured: !@point.is_featured)
    end
    redirect_to points_path
  end

  private

  def set_point_by_point_id
    @point = Point.find(params[:point_id])
  end

  def set_point
    @point = Point.find(params[:id])
  end

  def set_service
    @service = Service.find(params[:service_id])
  end

  # def set_topic
  #   @topic = Topic.find(params[:topic_id])
  # end

  def point_params
    params.require(:point).permit(:title, :source, :status, :rating, :analysis, :topic_id, :service_id, :is_featured)
  end
end
