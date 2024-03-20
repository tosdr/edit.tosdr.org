# frozen_string_literal: true

# app/policies/spam_policy.rb
class SpamPolicy < ApplicationPolicy
  def flag_as_spam?
    (!user.nil? && user.admin?) || (!user.nil? && user.curator?)
  end
end
