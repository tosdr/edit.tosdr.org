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

  def update?
    create? || owner?
  end

  def destroy?
    create? || owner?
  end

  def crawl?
    create? || owner?
  end

  def restore_points?
    owner?
  end

  private

  def owner?
    record.user.nil? ? (user.curator?) || (user.admin?) : (user == record.user)
  end
end
