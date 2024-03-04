# frozen_string_literal: true

# app/models/version.rb
class Version < ApplicationRecord
  belongs_to :item, polymorphic: true
end
