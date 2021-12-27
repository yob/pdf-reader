# typed: false
# coding: utf-8

# A custom matcher for confirming a Point is close to another point. This is helpful
# because the x and y co-ordinates of a point are floats so we can't match on them exactly
RSpec::Matchers.define :be_close_to do |close_to_point|
  match do |actual_point|
    (actual_point.x >= close_to_point.x - 0.01) &&
      (actual_point.x <= close_to_point.x + 0.01) &&
      (actual_point.y >= close_to_point.y - 0.01) &&
      (actual_point.y <= close_to_point.y + 0.01)
  end
  failure_message do |actual_point|
    "expected that (#{actual_point.x},#{actual_point.y}) would be within" +
      " 0.01 of (#{close_to_point.x},#{close_to_point.y})"
  end
end
