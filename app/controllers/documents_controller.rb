class DocumentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_document, only: [:show, :edit, :update]

  def index
    if @query = params[:query]
      @documents = Document.search_by_document_name(@query)
    else
      @documents = Document.all
    end
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      redirect_to @document
    else
      render 'new'
    end
  end

  def update
    @document.update(document_params)

    if @document.save
      redirect_to @document
    else
      render 'edit'
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:service_id, :name, :url, :xpath)
  end
end
