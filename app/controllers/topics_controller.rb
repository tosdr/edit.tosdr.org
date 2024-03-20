# frozen_string_literal: true

# app/controllers/topics_controller.rb
class TopicsController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_curator, except: %i[index show]
  before_action :set_topic, only: %i[show edit update destroy]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Topic

    @topics = Topic.all
    return unless @query == params[:query]

    @topics = Topic.search_by_topic_title(@query)
  end

  def create
    authorize Topic

    @topic = Topic.new(topic_params)
    if @topic.save
      redirect_to topics_path
    else
      render :new
    end
  end

  def new
    authorize Topic

    @topic = Topic.new
  end

  def edit
    authorize @topic
  end

  def show
    authorize @topic

    @cases = @topic.cases
    return unless @query == params[:query]

    @cases = Case.search_by_multiple(@query).where(topic: @topic)
  end

  def update
    authorize @topic

    @topic.update(topic_params)
    redirect_to topic_path(@topic)
  end

  def destroy
    authorize @topic

    if @topic.points.any?
      flash[:alert] = 'Users have contributed valuable insight to this topic!'
      redirect_to topic_path(@topic)
    else
      @topic.destroy
      flash[:notice] = 'Topic has been deleted!'
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
    render file: 'public/401.html', status: :unauthorized unless current_user.curator?
  end
end
