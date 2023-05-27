# frozen_string_literal: true

module ApplicationInteraction
  class Base < Grape::API
    mount ApplicationInteraction::V1::Base
  end
end
