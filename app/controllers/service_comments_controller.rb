# frozen_string_literal: true

# app/controllers/service_comments_controller.rb
class ServiceCommentsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_service, only: %i[new create]

  invisible_captcha only: [:create], honeypot: :subject

  def new
    @service_comment = ServiceComment.new
  end

  def create
    @service_comment = ServiceComment.new(service_comment_params)
    @service_comment.summary = Kramdown::Document.new(CGI.escapeHTML(@service_comment.summary)).to_html
    @service_comment.user_id = current_user.id
    @service_comment.service_id = @service.id

    if @service_comment.save
      report_spam(@service_comment.summary, 'ham') if current_user.admin || current_user.curator
      flash[:notice] = 'Comment added!'
      redirect_to service_path(@service)
    else
      render 'new'
    end
  end

  private

  def set_service
    @service = Service.find(params[:service_id])
  end

  def service_comment_params
    params.require(:service_comment).permit(:summary, :service_id)
  end
end
