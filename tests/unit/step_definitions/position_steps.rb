# frozen_string_literal: true
###############################################################################
# Step definitions for Position trait coverage.                               #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/objects/traits/position'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module PositionWorld
  attr_accessor :pos_object, :pos_sit_result, :pos_stand_result, :pos_lie_result
end
World(PositionWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Stub for GameObject so Position#on? can do `target.is_a? GameObject`
unless defined?(::GameObject)
  class ::GameObject; end
end

# A minimal target double with goid and name.
class PositionTargetDouble
  attr_reader :goid, :name

  def initialize(name, goid)
    @name = name
    @goid = goid
  end
end

# A target that also identifies as a GameObject (for on? branch).
# We override is_a?/kind_of? rather than relying on inheritance from
# ::GameObject because multiple step files may redefine ::GameObject
# in different load orders, making the subclass check unreliable.
class PositionGameObjectDouble
  attr_reader :goid, :name

  def initialize(name, goid)
    @name = name
    @goid = goid
  end

  def is_a?(klass)
    return true if klass == ::GameObject
    return true if klass.respond_to?(:name) && klass.name&.end_with?("GameObject")
    super
  end
  alias :kind_of? :is_a?
end

# A simple class that includes Position. The module calls `super` in
# initialize, so we give it a base that accepts *args.
class PositionTestHost
  include Position

  def initialize(*args)
    super
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a fresh positionable object') do
  @pos_object       = PositionTestHost.new
  @pos_sit_result   = nil
  @pos_stand_result = nil
  @pos_lie_result   = nil
end

Given('the position object is already sitting') do
  @pos_object.sit
end

Given('the position object is already lying') do
  @pos_object.lie
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the position object sits without a target') do
  @pos_sit_result = @pos_object.sit
end

When('the position object sits on a target named {string} with goid {string}') do |name, goid|
  target = PositionTargetDouble.new(name, goid)
  @pos_sit_result = @pos_object.sit(target)
end

When('the position object stands without a target') do
  @pos_stand_result = @pos_object.stand
end

When('the position object stands on a target named {string} with goid {string}') do |name, goid|
  target = PositionTargetDouble.new(name, goid)
  @pos_stand_result = @pos_object.stand(target)
end

When('the position object lies without a target') do
  @pos_lie_result = @pos_object.lie
end

When('the position object lies on a target named {string} with goid {string}') do |name, goid|
  target = PositionTargetDouble.new(name, goid)
  @pos_lie_result = @pos_object.lie(target)
end

When('the position pose is set to {string}') do |val|
  @pos_object.pose = val
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the position sit result should be true') do
  assert_equal true, @pos_sit_result
end

Then('the position sit result should be false') do
  assert_equal false, @pos_sit_result
end

Then('the position stand result should be true') do
  assert_equal true, @pos_stand_result
end

Then('the position stand result should be false') do
  assert_equal false, @pos_stand_result
end

Then('the position lie result should be true') do
  assert_equal true, @pos_lie_result
end

Then('the position lie result should be false') do
  assert_equal false, @pos_lie_result
end

Then('the position pose should be {string}') do |expected|
  assert_equal expected, @pos_object.pose
end

Then('the position pose should be nil') do
  assert_nil @pos_object.pose
end

Then('the position object should be sitting') do
  assert @pos_object.sitting?, "Expected object to be sitting"
end

Then('the position object should not be sitting') do
  assert !@pos_object.sitting?, "Expected object NOT to be sitting"
end

Then('the position object should be lying') do
  assert @pos_object.lying?, "Expected object to be lying"
end

Then('the position object should not be lying') do
  assert !@pos_object.lying?, "Expected object NOT to be lying"
end

Then('the position object should be prone') do
  assert @pos_object.prone?, "Expected object to be prone"
end

Then('the position object should not be prone') do
  assert !@pos_object.prone?, "Expected object NOT to be prone"
end

Then('the position object should be able to move') do
  assert @pos_object.can_move?, "Expected object to be able to move"
end

Then('the position object should not be able to move') do
  assert !@pos_object.can_move?, "Expected object NOT to be able to move"
end

Then('the position sitting_on should be {string}') do |expected|
  assert_equal expected, @pos_object.sitting_on
end

Then('the position sitting_on should be nil') do
  assert_nil @pos_object.sitting_on
end

Then('the position lying_on should be {string}') do |expected|
  assert_equal expected, @pos_object.lying_on
end

Then('the position lying_on should be nil') do
  assert_nil @pos_object.lying_on
end

Then('the position object should be on something') do
  assert @pos_object.on?, "Expected on?() to be true"
end

Then('the position object should not be on something') do
  assert !@pos_object.on?, "Expected on?() to be false"
end

Then('the position object should be on goid {string}') do |goid|
  assert @pos_object.on?(goid), "Expected on?(#{goid.inspect}) to be true"
end

Then('the position object should not be on goid {string}') do |goid|
  assert !@pos_object.on?(goid), "Expected on?(#{goid.inspect}) to be false"
end

Then('the position object should be on a game object with goid {string}') do |goid|
  go = PositionGameObjectDouble.new("thing", goid)
  assert @pos_object.on?(go), "Expected on?(GameObject) to be true"
end
