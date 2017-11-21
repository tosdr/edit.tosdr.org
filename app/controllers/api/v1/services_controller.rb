class Api::V1::ServicesController < Api::V1::BaseController
  def index
    @services = policy_scope(Service)
  end
end
