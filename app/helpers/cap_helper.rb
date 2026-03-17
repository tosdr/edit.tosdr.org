# frozen_string_literal: true

module CapHelper
  def cap_enabled?
    ENV["CAP_API_ENDPOINT"].present? && ENV["CAP_SECRET_KEY"].present?
  end

  def cap_api_endpoint
    ENV["CAP_API_ENDPOINT"]
  end
end
