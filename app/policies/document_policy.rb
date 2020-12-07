class DocumentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    !user.nil?
  end

  def update?
    (!user.nil? && is_owner?) || (!user.nil? && user.curator?)
  end

  def destroy?
    (!user.nil? && is_owner?) || (!user.nil? && user.curator?)
  end

  private

  def is_owner?
    record.user.nil? ? (user.curator?) : (user == record.user)
  end
end
