# frozen_string_literal: true

# app/decorators/version/version_decorator.rb
class Version::VersionDecorator
  attr_reader :version, :user, :item

  def initialize(version, user, item)
    @version = version
    @user = user
    @item = item
  end
end
