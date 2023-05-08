# frozen_string_literal: true

module ApplicationInteraction
  module V1
    class Base < Grape::API
      mount ApplicationInteraction::V1::Points
      mount ApplicationInteraction::V1::Cases
    end
  end
end
