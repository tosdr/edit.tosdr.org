# frozen_string_literal: true

module ApplicationInteraction
  module Entities
    class Point < Grape::Entity
      expose :id, :title, :annotation_ref
    end
  end
end
