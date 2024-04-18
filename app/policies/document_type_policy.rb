# frozen_string_literal: true

# app/policies/document_type_policy.rb
class DocumentTypePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    index?
  end

  def create?
    !user.nil?
  end

  def new?
    create?
  end

  def edit?
    (!user.nil? && owner?) || !user.nil? && privileged?
  end

  def update?
    edit?
  end

  def review?
    !user.nil? && privileged?
  end

  def destroy?
    false
  end

  private

  def privileged?
    user.curator? || user.admin?
  end

  def owner?
    record.user.nil? ? (user.curator? || user.admin?) : (user == record.user)
  end
end
