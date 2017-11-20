class Api::V1::TopicsController < Api::V1::BaseController
  def index
    @topics = policy_scope(Topic)
  end
end
