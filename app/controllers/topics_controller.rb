class TopicsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_curator, except: [:index, :show]
  before_action :set_topic, only: [:show, :edit, :update, :destroy]

  def index
    @topics = Topic.all
    if @query = params[:query]
      @topics = Topic.search_by_topic_title(@query)
    end
  end

  def create
    @topic = Topic.new(topic_params)
    if @topic.save
      redirect_to topics_path
    else
      render :new
    end
  end

  def new
    @topic = Topic.new
  end

  def edit
  end

  def show
    @cases = @topic.cases
    if @query = params[:query]

      @cases = Case.search_by_multiple(@query).where(topic: @topic)

    end
  end

  def update
    @topic.update(topic_params)
    redirect_to topic_path(@topic)
  end

  def destroy
    if @topic.points.any?
      flash[:alert] = "Users have contributed valuable insight to this topic!"
      redirect_to topic_path(@topic)
    else
      @topic.destroy
      flash[:notice] = "Topic has been deleted!"
      redirect_to topics_path
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:title, :subtitle, :description, :query)
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end
