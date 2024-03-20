# frozen_string_literal: true

# app/policies/document_policy.rb
class DocumentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    index?
  end

  def create?
    (!user.nil? && user.curator?) || (!user.nil? && user.admin?)
  end

  def edit?
    create? || (!user.nil? && owner?)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def crawl?
    edit?
  end

  def restore_points?
    !user.nil? && owner?
  end

  private

  def owner?
    record.user.nil? ? (user.curator?) || (user.admin?) : (user == record.user)
  end
end
