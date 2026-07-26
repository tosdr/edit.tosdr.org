# frozen_string_literal: true

# app/policies/point_policy.rb
class PointPolicy < ApplicationPolicy
  def index?
    !user.nil?
  end

  def show?
    true
  end

  def new?
    !user.nil?
  end

  def create?
    new?
  end

  def edit?
    (!user.nil? && owner?) || docbot_curator?
  end

  def update?
    edit?
  end

  # Soft delete (points#destroy) is an admin-only moderation action, deliberately wider
  # than edit?: an admin can hide any point, including ones they cannot otherwise edit.
  def destroy?
    !user.nil? && user.admin?
  end

  def review?
    peer_curator?
  end

  def review_queue?
    user.curator?
  end

  def post_review?
    review?
  end

  def approve?
    review?
  end

  def decline?
    review?
  end

  def veto?
    !user.nil? && user.level_two? && user != record.user && record.auto_approval_countdown?
  end

  def user_points?
    new?
  end

  private

  def owner?
    record.user.nil? ? user.curator? : (user == record.user)
  end

  def docbot_curator?
    record.user.username == 'docbot' && !user.nil? && user.curator?
  end

  def peer_curator?
    user.curator? && (user != record.user)
  end
end
