class DocumentCommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_document, only: [:new, :create]

  invisible_captcha only: [:create], honeypot: :subject

  def new
    @document_comment = DocumentComment.new
  end

  def create
    puts document_comment_params
    puts @document.id
    @document_comment = DocumentComment.new(document_comment_params)
	@document_comment.summary = Kramdown::Document.new(CGI::escapeHTML(@document_comment.summary)).to_html
    @document_comment.user_id = current_user.id
    @document_comment.document_id = @document.id

    if @document_comment.save
      flash[:notice] = "Comment added!"
    else
      flash[:notice] = "Error adding comment!"
      puts @document_comment.errors.full_messages
    end
    redirect_to document_path(@document)
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def document_comment_params
    params.require(:document_comment).permit(:summary, :document_id)
  end
end
