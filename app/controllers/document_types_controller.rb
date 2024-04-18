# frozen_string_literal: true

# app/controllers/document_types_controller.rb
class DocumentTypesController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_document_type, only: %i[show edit update review]
  before_action :set_documents, only: :show

  def index
    authorize DocumentType
    @q = DocumentType.ransack(params[:q])
    @document_types = @q.result(distinct: true).page(params[:page] || 1)
  end

  def show
    authorize @document_type
  end

  def new
    authorize DocumentType

    @document_type = DocumentType.new
    @submit_text = current_user.admin || current_user.curator ? 'Create' : 'Request'
  end

  def create
    authorize DocumentType

    @document_type = DocumentType.new(document_type_params)
    current_user_privileged = current_user.admin || current_user.curator
    @document_type.status = 'pending' unless current_user_privileged

    @document_type.user = current_user

    if @document_type.save
      redirect_to document_type_path(@document_type)
    else
      render 'new'
    end
  end

  def edit
    authorize @document_type

    @submit_text = 'Update'
  end

  def update
    authorize @document_type

    @document_type.update(document_type_params)
    if @document_type.save
      flash[:notice] = 'Document type updated'
      redirect_to document_type_path(@document_type)
    else
      render 'edit'
    end
  end

  def review
    authorize @document_type

    @document_type.status = params[:status]
    if @document_type.save
      flash[:notice] = 'Updated status of document type'
      redirect_to document_type_path(@document_type)
    else
      flash[:error] = 'There was an error updating the document type'
    end
  end

  private

  def set_document_type
    @document_type = DocumentType.find(params[:id])
  end

  def set_documents
    document_type = DocumentType.find(params[:id])
    @documents = document_type.documents
  end

  def document_type_params
    params.require(:document_type).permit(:user_id, :name, :status, :description)
  end
end
