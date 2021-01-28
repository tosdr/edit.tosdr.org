class CasePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def list_all?
    true
  end

  def new?
    !user.nil? && user.curator?
  end

  def create?
    !user.nil? && user.curator?
  end

  def edit?
    !user.nil? && user.curator?
  end

  def update?
    !user.nil? && user.curator?
  end

  def destroy?
    !user.nil? && user.curator?
  end
end
