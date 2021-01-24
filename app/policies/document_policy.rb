class DocumentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    (!user.nil? && user.curator?) || (!user.nil? && user.admin?)
  end

  def update?
    (!user.nil? && user.curator?) || (!user.nil? && user.admin?)
  end

  def destroy?
    (!user.nil? && user.curator?) || (!user.nil? && user.admin?)
  end

  def crawl?
    (!user.nil? && user.curator?) || (!user.nil? && user.admin?)
  end

  private

  def is_owner?
    record.user.nil? ? (user.curator?) || (user.admin?) : (user == record.user)
  end
end
