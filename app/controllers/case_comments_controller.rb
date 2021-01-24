class CaseCommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_case, only: [:new, :create]

  invisible_captcha only: [:create], honeypot: :subject

  def new
    @case_comment = CaseComment.new
  end

  def create
    puts case_comment_params
    puts @case.id
    @case_comment = CaseComment.new(case_comment_params)
	@case_comment.summary = Kramdown::Document.new(CGI::escapeHTML(@case_comment.summary)).to_html
    @case_comment.user_id = current_user.id
    @case_comment.case_id = @case.id

    if @case_comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:notice] = "Error adding comment!"
      puts @case_comment.errors.full_messages
    end
    redirect_to case_path(@case)
  end

  private

  def set_case
    @case = Case.find(params[:case_id])
  end

  def case_comment_params
    params.require(:case_comment).permit(:summary, :case_id)
  end
end
