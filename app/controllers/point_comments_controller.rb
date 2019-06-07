class PointCommentsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create]
  before_action :set_point, only: [:new, :create]

  def new
    @point_comment = PointComment.new
  end

  def create
    @point_comment = PointComment.new(point_comment_params)
    @point_comment.user_id = current_user.id
    @point_comment.point_id = @point.id

    if @point_comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:error] = "Error adding comment!"
      puts @point_comment.errors.full_messages
    end

    redirect_to service_point_path(@point.service, @point)
  end

  private

  def set_point
    @point = Point.find(params[:id])
  end

  def point_comment_params
    params.require(:point_comment).permit(:summary, :point_id)
  end
end
