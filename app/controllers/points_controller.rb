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
    @versions = @point.versions
    @reasons = @point.reasons
    @comments = Comment.where(point_id: @point.id)

    @point_info = {
      service_name: @point.service.name,
      status: @point.status,
      rating: @point.rating,
      changes: @point.versions.size,
      title: @point.title,
      analysis: @point.analysis
    }

    # formats the versions in advance so the logic is done in the controller
    # and not in the view
    # not in use right now, but may be a good idea to use when improving
    # the UX of the versions table in the point show page
    # the method figures_for_versions_object is in the point model, along with an explanation
    @formatted_versions = @point.figures_for_versions_object(@point)
  end

  def update
    # the logic beforehand was incorrect; the reason must be created after the point has been updated, and then the reason must be saved in the same block that the point is being updated in
    # to check if the reasons are persisting, do this in the rails console:
    # 1. point = Point.find(id)
    # 2. point.reasons

    if point_params[:reason].empty?
      flash[:alert] = "You must provide a reason for your changes"
      render :edit
    else
      @point.update(point_params)
      r = Reason.new(point_id: @point.id, content: @point.reason, user_id: current_user.id, status: @point.status)
      r.save!
      flash[:notice] = "Point successfully updated!"
      redirect_to point_path(@point)
    end
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

  def point_params
    params.require(:point).permit(:title, :source, :status, :rating, :analysis, :topic_id, :service_id, :is_featured, :query, :reason)
  end
end
