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
  end

  def update
  end

  def destroy
  end

  private
  def set_case
    @case = Case.find(params[:id])
  end

  def params
  end

  def set_curator
    unless current_user.curator?
      render :file => "public/401.html", :status => :unauthorized
    end
  end

end
