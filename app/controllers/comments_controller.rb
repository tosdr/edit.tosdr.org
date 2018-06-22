class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_point, only: [:new, :create]
  def new
    @comment = Comment.new
  end

  def create
    @comment = Comment.new(comment_params)
    @comment.point = @point
    @comment.user_id = current_user.id

    if @comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:notice] = "Error adding comment!"
      puts @comment.errors.full_messages
    end
    redirect_to point_path(@point)
  end

  private

  def set_point
    @point = Point.find(params[:point_id])
  end

  def comment_params
    params.require(:comment).permit(:summary)
  end
end
