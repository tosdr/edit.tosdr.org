class PointCommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_point, only: [:new, :create]

  invisible_captcha only: [:create], honeypot: :subject

  def new
    @point_comment = PointComment.new
  end

  def create
    puts point_comment_params
    puts @point.id
    @point_comment = PointComment.new(point_comment_params)
	@point_comment.summary = Kramdown::Document.new(CGI::escapeHTML(@point_comment.summary)).to_html
    @point_comment.user_id = current_user.id
    @point_comment.point_id = @point.id

    if @point_comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:notice] = "Error adding comment!"
      puts @point_comment.errors.full_messages
    end
    redirect_to point_path(@point)
  end

  private

  def set_point
    @point = Point.find(params[:point_id])
  end

  def point_comment_params
    params.require(:point_comment).permit(:summary, :point_id)
  end
end
