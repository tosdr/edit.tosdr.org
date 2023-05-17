# frozen_string_literal: true

module ApplicationInteraction
  module Entities
    class Case < Grape::Entity
      expose :id, :title
    end
  end
end