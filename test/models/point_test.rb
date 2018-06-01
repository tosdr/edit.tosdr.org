require 'test_helper'

class PointTest < ActiveSupport::TestCase
  test 'should not save point without title' do
    point = Point.new
    assert_not point.save
  end
end

