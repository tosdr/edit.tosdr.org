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

  def review?
    peer_curator?
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
