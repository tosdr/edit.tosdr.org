class TopicPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    index?
  end

  def create?
    (!user.nil? && user.admin?)
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

  private

  def owner?
    record.user.nil? ? (user.curator?) || (user.admin?) : (user == record.user)
  end
end
