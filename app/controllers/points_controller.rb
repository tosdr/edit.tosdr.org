class PointsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_curator, only: [:edit, :featured, :destroy]
  before_action :set_point, only: [:show, :edit, :featured, :update, :destroy]

  def index
    if params[:scope].nil? || params[:scope] == "all"
      @points = Point.includes(:service).all
    elsif params[:scope] == "pending"
      @points = Point.all.where(status: "pending")
    end
    if @query = params[:query]
      @points = Point.includes(:service).search_points_by_multiple(@query)
    end
  end

  def new
    @point = Point.new
    @topics = Topic.all
    @cases = Case.includes(:topic).all
    if @query = params[:service_id]
      @point['service_id'] = params[:service_id]
    end
    @service_url = @point.service ? @point.service.url : ''
  end

  def create
    @point = Point.new(point_params)
    @cases = Case.includes(:topic).all

    @point.user = current_user

    if params[:only_create]
      if @point.save
        @point.topic_id = @point.case.topic_id
        redirect_to service_path(@point.service)
      elsif @point.case.nil?
        render :new
      else
        render :new
      end
    elsif params[:create_add_another]
      if @point.save
        @point.topic_id = @point.case.topic_id
        redirect_to new_point_path
        flash[:notice] = "You created a point! Feel free to add another."
      elsif @point.case.nil?
        render :new
      else
        render :new
      end
    end
  end

  def edit
    @service_url = @point.service.url
    @cases = Case.includes(:topic).all
  end

  def show
    @comments = Comment.where(point_id: @point.id)
    @versions = @point.versions
  end

  def update
    @cases = Case.includes(:topic).all
    if @point.update(point_params)
      @point.topic_id = @point.case.topic_id
      comment = create_comment(@point)
      redirect_to point_path
    elsif @point.case.nil?
      render :edit
    else
      render :edit
    end
    # copied_params = point_params
    #
    # if (copied_params['case_id'] != @point.case_id.to_s)
    #   puts 'case change, setting title, description, rating and topic'
    #   @case = Case.find(copied_params['case_id'])
    #   copied_params['topic_id'] = @case.topic_id
    #   copied_params['title'] = @case.title
    #   copied_params['analysis'] = @case.description || @case.title
    #   if (@case.classification == 'blocker')
    #     copied_params['rating'] = 0
    #   end
    #   if (@case.classification == 'bad')
    #     copied_params['rating'] = 2
    #   end
    #   if (@case.classification == 'neutral')
    #     copied_params['rating'] = 5
    #   end
    #   if (@case.classification == 'good')
    #     copied_params['rating'] = 8
    #   end
    # end
  end

  def create_comment(point)
    Comment.create(point_id: point.id, summary: point.point_change, user_id: current_user.id)
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

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end
