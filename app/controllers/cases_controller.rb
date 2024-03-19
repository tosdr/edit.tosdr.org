# frozen_string_literal: true

# app/controllers/cases_controller.rb
class CasesController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!, except: %i[index show list_all]
  before_action :set_curator, only: [:destroy]
  before_action :set_case, only: %i[show edit update destroy]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def index
    authorize Case
  end

  def list_all
    authorize Case

    object = []
    cases = Case.all
    cases.map do |c|
      object << { pointbox: c.determine_pointbox, case: c }
    end

    respond_to do |format|
      format.json { render json: object }
    end
  end

  def new
    authorize Case

    @case = Case.new
  end

  def edit
    authorize @case
  end

  def create
    authorize Case

    @case = Case.new(case_params)
    if @case.save
      redirect_to case_path(@case)
    else
      render :new
    end
  end

  def show
    authorize @case

    @points = @case.points.includes(:service).includes(:user)
    @points = @points.search_points_by_multiple(params[:query]) if params[:query]
  end

  def update
    authorize @case

    @case.update(case_params)
    flash[:notice] = 'Case has been updated!'
    redirect_to case_path(@case)
  end

  def destroy
    authorize @case

    if @case.points.any?
      flash[:alert] = 'Users have contributed valuable insight to this case!'
      redirect_to case_path(@case)
    else
      @case.destroy
      flash[:notice] = 'Case has been deleted!'
      redirect_to cases_path
    end
  end

  private

  def set_case
    @case = Case.find(params[:id])
  end

  def case_params
    params.require(:case).permit(:classification, :score, :title, :description, :topic_id, :privacy_related, :docbot_regex)
  end

  def set_curator
    return if current_user.curator?

    render file: 'public/401.html', status: :unauthorized
  end
end
