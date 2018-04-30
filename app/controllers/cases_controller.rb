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

  def show
    @points = @case.points
    if @query = params[:query]
      @points = Points.search_points_by_multiple(@query).where(case: @case)
      puts @case_points
    end
  end

  def update
    @case.update(case_params)
    flash[:notice] = "Case has been updated!"
    redirect_to case_path(@case)
  end

  def destroy
    if @case.points.any?
      flash[:alert] = "Users have contributed valuable insight to this case!"
      redirect_to case_path(@case)
    else
      @case.destroy
      flash[:notice] = "Case has been deleted!"
      redirect_to cases_path
    end
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
