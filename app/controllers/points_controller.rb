class PointsController < ApplicationController
  before_action :set_point

  def index
    @points = Point.all
  end

  def new
    if current_user
      @point = Point.new
    else
      flash[:notice] = "Please log in before adding a point"
      redirect_to new_user_path
    end
  end

  def create
    @point = Point.new(point_params)
    @point.user_id = current_user
    # need to instantiate the services ?
    # @point.service_id = @service(params[:id])
    # @point.topid_id = @topic(params[:id])
    # if yes, TODO: create the setting private methods
    if @point.save
      flash[:notice] = "You created a point!"
      redirect_to points_path
    else
      render :new
    end
  end

  def edit
    @point = Point.find(params[:id])
  end

  def show
    @point = Point.find(params[:id])
  end

  def update
    @point = Point.find(params[:id])
    @point.update(point_params)
    flash[:notice] = "Point successfully updated!"
    redirect_to points_path
  end

  def destroy
    @point = Point.find(params[:id])
    @point.destroy
    redirect_to points_path
  end

  private
  def set_point
    @point = Point.find(params[:point_id])
  end

  def point_params
    params.require(:point).permit(:title, :source, :analysis, :topic_id)
  end
end
