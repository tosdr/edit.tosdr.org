class ServicePolicy < ApplicationPolicy
  def index?
    true
  end

  def list_all?
    true
  end

  def service_pending_points?
    true
  end

  def show?
    true
  end

  def annotate?
    true
  end

  def quote?
    true
  end

  def create?
    !user.nil?
  end

  def update?
    (!user.nil? && is_owner?) || (!user.nil? && user.curator?)
  end

  def destroy?
    (!user.nil? && user.curator?)
  end

  private

  def is_owner?
    record.user.nil? ? (user.curator?) : (user == record.user)
  end
end
