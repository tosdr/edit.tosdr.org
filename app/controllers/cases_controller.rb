class CasesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_curator, except: [:index, :show]
  before_action :set_case, only: [:show, :edit, :update, :destroy]

  def index
    @cases = Case.all
  end

  def new
    @case = Case.new
  end

  def edit
  end

  def create
    @case = Case.new(case_params)
    if @case.save
      redirect_to cases_path
    else
      render :new
    end
  end

  def update
  end

  def destroy
  end

  private
  def set_case
    @case = Case.find(params[:id])
  end

  def case_params
    params.require(:case).permit(:classification, :score, :title, :description, :topic_id)
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end

end
