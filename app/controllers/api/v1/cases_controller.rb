class Api::V1::CasesController < Api::V1::BaseController
  before_action :set_case, only: [ :show ]
  def index
    policy_scope(Case)
    @cases = Case.all
  end

  def show
  end

  private

  def set_case
    @case = Case.find(params[:id])
    authorize @case
  end
end
