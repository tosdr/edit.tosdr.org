# frozen_string_literal: true

# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    true
  end
end
