class ServiceCommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_service, only: [:new, :create]

  invisible_captcha only: [:create], honeypot: :subject

  def new
    @service_comment = ServiceComment.new
  end

  def create
    puts service_comment_params
    puts @service.id
    @service_comment = ServiceComment.new(service_comment_params)
	@service_comment.summary = Kramdown::Document.new(CGI::escapeHTML(@service_comment.summary)).to_html
    @service_comment.user_id = current_user.id
    @service_comment.service_id = @service.id

    if @service_comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:notice] = "Error adding comment!"
      puts @service_comment.errors.full_messages
    end
    redirect_to service_path(@service)
  end

  private

  def set_service
    @service = Service.find(params[:service_id])
  end

  def service_comment_params
    params.require(:service_comment).permit(:summary, :service_id)
  end
end
