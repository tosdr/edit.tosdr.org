class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_curator, except: [:index, :show]
  before_action :set_point, only: [:new, :create]
  before_action :set_admin
  def new
    @comment = Comment.new
  end

  def create
    @comment = Comment.new(comment_params)
    @comment.point = @point

    if @comment.save
      flash[:notice] = "Comment saved!"
      redirect_to point_path(@point)
    else
      puts @comment.errors.full_messages
      redirect_to point_path(@point)
    end
  end

  private

  def set_admin
    unless current_user.curator?
      redirect_to root_path
      flash[:alert] = "You must be a curator"
    end
  end

  def set_point
    @point = Point.find(params[:point_id])
  end

  def comment_params
    params.require(:comment).permit(:summary)
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end
end
