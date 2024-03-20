# frozen_string_literal: true

# app/policies/version_policy.rb
class VersionPolicy < ApplicationPolicy
  def index?
    !user.nil?
  end
end
