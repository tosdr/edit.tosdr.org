class TopicCommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_topic, only: [:new, :create]

  invisible_captcha only: [:create], honeypot: :subject

  def new
    @topic_comment = TopicComment.new
  end

  def create
    @topic_comment = TopicComment.new(topic_comment_params)
	@topic_comment.summary = Kramdown::Document.new(CGI::escapeHTML(@topic_comment.summary)).to_html
    @topic_comment.user_id = current_user.id
    @topic_comment.topic_id = @topic.id

    if @topic_comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:notice] = "Error adding comment!"
      puts @topic_comment.errors.full_messages
    end
    redirect_to topic_path(@topic)
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end

  def topic_comment_params
    params.require(:topic_comment).permit(:summary, :topic_id)
  end
end
