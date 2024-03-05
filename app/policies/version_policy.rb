class VersionPolicy < ApplicationPolicy
  def index?
    !user.nil?
  end
end
