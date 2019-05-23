class PointPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def new?
    !user.nil?
  end

  def create?
    !user.nil?
  end

  def edit?
    !user.nil? && is_owner?
  end

  def update?
    !user.nil? && is_owner?
  end

  def review?
    user.curator? && (user != record.user)
  end

  def post_review?
    user.curator? && (user != record.user)
  end

  def user_points?
    !user.nil?
  end

  private

  def is_owner?
    record.user.nil? ? (user.curator?) : (user == record.user)
  end

end
