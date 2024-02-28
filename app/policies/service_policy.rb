class ServicePolicy < ApplicationPolicy
  def index?
    true
  end

  def list_all?
    index?
  end

  def service_pending_points?
    index?
  end

  def show?
    index?
  end

  def annotate?
    index?
  end

  def quote?
    index?
  end

  def create?
    (!user.nil? && user.curator?) || (!user.nil? && user.admin?)
  end

  def update?
    create? || owner?
  end

  def destroy?
    create? || owner?
  end

  private

  def owner?
    record.user.nil? ? (user.curator?) || (user.admin?) : (user == record.user)
  end
end
