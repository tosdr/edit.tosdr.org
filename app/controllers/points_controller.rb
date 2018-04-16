class PointsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_point, only: [:show, :edit,:featured, :update, :destroy]

  def index
   @points = Point.all
   if @query = params[:query]
    @points = Point.search_points_by_multiple(@query)
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

    if params[:has_case]
      @point.update_parameters(title: @case.title, rating: @case.score, analysis: @case.description, topic_id: @case.topic_id, service_id: @case.service_id)
      if @point.save
        redirect_to points_path
        flash[:notice] = "You created a point!"
      else
        render :new
      end
    elsif params[:only_create]
      # @point.update_parameters(point_params)
      if @point.save!
        redirect_to points_path
        flash[:notice] = "You created a point!"
      else
        render :new
      end
    elsif params[:create_add_another]
      # @point.update_parameters(point_params)
      if @point.save!
        redirect_to new_point_path
        flash[:notice] = "You created a point! Feel free to add another."
      else
        render :new
      end
    else
      # the page goes directly here and doesn't get in the loop
      # there is definitly something wrong with this method
      # investigating...
      # raise
      flash[:error] = @point.errors.full_messages
    end
  end

  def edit
  end

  def show
    puts @point.id
    @comments = Comment.where(point_id: @point.id)
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
        redirect_to points_path
      else
        flash[:alert] = "There are already five featured points for this service!"
        redirect_to point_path(@point)
      end
    elsif @point.is_featured?
      @point.update(is_featured: !@point.is_featured)
      redirect_to points_path
    end
  end

  def user_points
    @points = current_user.points
    if @query = params[:query]
      @points = Point.search_points_by_multiple(@query)
    end
  end

  private

  def set_point
    @point = Point.find(params[:id])
  end

  def set_service
    @service = Service.find(params[:service_id])
  end

  def set_case
    @case = Case.find(params[:case_id])
  end

  def point_params
    params.require(:point).permit(:title, :source, :status, :rating, :analysis, :topic_id, :service_id, :is_featured, :query)
  end
end
