class PointsController < ApplicationController
  def index
    @points = Point.all
  end

  def new
    if current_user
      @point = Point.new
    else
      flash[:notice] = "Please log in or sign up to create a point."
      redirect_to new_user_path
    end
  end

  def create
    @point = Point.new(point_params)
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
    params.require(:point).permit
  end
end
