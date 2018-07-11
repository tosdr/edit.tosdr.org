# require '/lib/tosbackdoc'

class DocRevisionsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_curator, only: [:destroy]
  before_action :set_docRevision, only: [:show, :edit, :update, :destroy]

  def index
    @docRevisions = DocRevision.all
  end

  def new
    @docRevision = DocRevision.new
  end

  def edit
  end

  def create
    @docRevision = DocRevision.new(docRevision_params)
    if @docRevision.save
      redirect_to docRevisions_path
    else
      render :new
    end
  end

  def show
  end

  def update
    @docRevision.update(docRevision_params)
    flash[:notice] = "DocRevision has been updated!"
    redirect_to docRevision_path(@docRevision)
  end

  def destroy
    if @docRevision.points.any?
      flash[:alert] = "Users have contributed valuable insight to this docRevision!"
      redirect_to docRevision_path(@docRevision)
    else
      @docRevision.destroy
      flash[:notice] = "DocRevision has been deleted!"
      redirect_to docRevisions_path
    end
  end

  def crawl
    @tbdoc = TOSBackDoc.new({
      url: @docRevision.url,
      xpath: @docRevision.xpath
    })
    @tbdoc.scrape
    @docRevision.update({ text: @tbdoc.newdata })
  end

  private
  def set_docRevision
    @docRevision = DocRevision.find(params[:id])
  end

  def docRevision_params
    params.require(:docRevision).permit(:classification, :score, :title, :description, :topic_id, :privacy_related)
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end

end
