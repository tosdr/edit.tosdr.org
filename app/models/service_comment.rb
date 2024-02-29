# frozen_string_literal: true

# app/models/service_comment.rb
class ServiceComment < ApplicationRecord
  validates :summary, presence: true
  belongs_to :service
  belongs_to :user
  has_many :spams, as: :spammable
end
