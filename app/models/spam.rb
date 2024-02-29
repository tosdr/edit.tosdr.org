# frozen_string_literal: true

# app/models/spam.rb
class Spam < ApplicationRecord
  belongs_to :spammable, polymorphic: true
end
