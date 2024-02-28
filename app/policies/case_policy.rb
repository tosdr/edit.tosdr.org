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
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  def destroy?
    new?
  end
end
