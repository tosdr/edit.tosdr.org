class Api::V1::CasesController < Api::V1::BaseController
  before_action :set_case, only: [:show]

  def index
    policy_scope(Case)
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
    return
    #
    # @cases = Case.all
  end

  def show
  end

  private

  def set_case
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
  end
end
