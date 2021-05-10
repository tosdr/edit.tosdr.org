class Api::V1::TopicsController < Api::V1::BaseController
  before_action :set_topic, only: [ :show ]

  def index
    policy_scope(Topic)
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
  end

  def show
    @topic
  end

  private
  def set_topic
    render json: { see: "https://tosdr.atlassian.net/l/c/6gWVHRND" }
  end
end
