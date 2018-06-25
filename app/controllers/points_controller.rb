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
    @services = Service.all
    @topics = Topic.all
    @cases = Case.all
    if @query = params[:service_id]
      @point['service_id'] = params[:service_id]
    end
    @service_url = @point.service ? @point.service.url : ''
  end

  def create
    @point = Point.new(point_params)
    @point.user = current_user
    if params[:has_case]
      if @point.case.nil? || @point.status.blank? || @point.source.blank?
        flash[:alert] = "Oops! If you use a case, make sure that all the form fields are filled in before submitting!"
        render :new
      elsif
        @point.update(title: @point.case.title, rating: @point.case.score, analysis: @point.case.description || @point.case.title, topic_id: @point.case.topic_id)
        if @point.save
          redirect_to service_path(@point.service)
          flash[:notice] = "You created a point!"
        else
          render :new
        end
      end
    elsif params[:only_create]
      if @point.save
        redirect_to service_path(@point.service)
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
    puts @point.errors.full_messages
  end

  def edit
    @service_url = @point.service.url
  end

  def show
    @point
    @comments = Comment.where(point_id: @point.id)
    @comments.each do |c|
      #if (c.user_id)
      #  c.user_id = User.find_by_id(c.user_id)
      #  puts c.user_id
      #end
    end
    @versions = @point.versions
  end

  def update
    comment_params = {
      summary: point_params['point_change']
    }
    puts comment_params
    comment = Comment.new(comment_params)
    comment.point = @point
    comment.user_id = current_user.id
    comment.save
    if comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:notice] = "Error adding comment!"
      puts comment.errors.full_messages
    end

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

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end

