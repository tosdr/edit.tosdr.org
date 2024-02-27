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
    (!user.nil? && is_owner?) || is_docbot_curator?
  end

  def update?
    !user.nil? && is_owner? || is_docbot_curator?
  end

  def review?
    is_peer_curator?
  end

  def post_review?
    is_peer_curator?
  end

  def approve?
    is_peer_curator?
  end

  def decline?
    is_peer_curator?
  end

  def user_points?
    !user.nil?
  end

  private

  def is_owner?
    record.user.nil? ? user.curator? : (user == record.user)
  end

  def is_docbot_curator?
    record.user.username == 'docbot' && !user.nil? && user.curator?
  end

  def is_peer_curator?
    user.curator? && (user != record.user)
  end
end
