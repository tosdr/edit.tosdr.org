class TopicCommentsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_topic, only: %i[new create]

  invisible_captcha only: [:create], honeypot: :subject

  def new
    @topic_comment = TopicComment.new
  end

  def create
    @topic_comment = TopicComment.new(topic_comment_params)
    @topic_comment.summary = Kramdown::Document.new(CGI.escapeHTML(@topic_comment.summary)).to_html
    @topic_comment.user_id = current_user.id
    @topic_comment.topic_id = @topic.id

    if @topic_comment.save
      report_spam(@topic_comment.summary, 'ham') if current_user.admin || current_user.curator
      flash[:notice] = 'Comment added!'
    else
      flash[:notice] = 'Error adding comment!'
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
