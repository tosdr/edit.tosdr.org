class PointsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_curator, only: [:edit, :featured, :destroy]
  before_action :set_point, only: [:show, :edit, :featured, :update, :destroy]
  before_action :points_get, only: [:index]

  def index
    @points = Point.all
    if @query = params[:query]
      @points = Point.includes(:service).search_points_by_multiple(@query)
    end
  end

  def new
    @point = Point.new
    @services = Service.all
    @topics = Topic.all
    @cases = Case.all
    @service_url = @point.service ? @point.service.url : ''
  end

  def create
    @point = Point.new(point_params)
    @point.user = current_user
    @cases = Case.all
    if @point.save
      redirect_to points_path
    else
      render :new
    end
  end

  def edit
    @service_url = @point.service.url
  end

  def show
    @point
    @comments = Comment.where(point_id: @point.id)
    @versions = @point.versions
    @reasons = @point.reasons
  end

  def update
    copied_params = point_params
    if (copied_params['case_id'] != @point.case_id.to_s)
      puts 'case change, setting title, description, rating and topic'
      @case = Case.find(copied_params['case_id'])
      copied_params['topic_id'] = @case.topic_id
      copied_params['title'] = @case.title
      copied_params['analysis'] = @case.description || @case.title
      if (@case.classification == 'blocker')
        copied_params['rating'] = 0
      end
      if (@case.classification == 'bad')
        copied_params['rating'] = 2
      end
      if (@case.classification == 'neutral')
        copied_params['rating'] = 5
      end
      if (@case.classification == 'good')
        copied_params['rating'] = 8
      end
    end
    @point.update(copied_params)
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

  def set_case
    @case = Case.find(params[:case_id])
  end

  def point_params
    params.require(:point).permit(:title, :source, :status, :rating, :analysis, :topic_id, :service_id, :is_featured, :query, :point_change, :case_id, :quoteDoc, :quoteRev, :quoteStart, :quoteEnd, :quoteText)
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

