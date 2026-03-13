# frozen_string_literal: true
###############################################################################
# Step definitions for AcommentCommand action coverage.                       #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/acomment'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AcommentWorld
  attr_accessor :acomment_cmd_player, :acomment_cmd_room, :acomment_cmd_target,
                :acomment_cmd_target_name, :acomment_cmd_comment,
                :acomment_cmd_find_returns_nil, :acomment_cmd_command
end
World(AcommentWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AcommentMockPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize
    @container = "acomment_room_goid_1"
    @name      = "TestAdmin"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Room double.
class AcommentMockRoom
  attr_accessor :name, :goid

  def initialize(name = "Test Room")
    @name = name
    @goid = "acomment_room_goid_1"
  end
end

# Target object double with comment attribute.
class AcommentMockObject
  attr_accessor :name, :comment

  def initialize(name = "Test Object")
    @name    = name
    @comment = nil
  end

  def to_s
    @name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed acomment_cmd environment') do
  @acomment_cmd_player           = AcommentMockPlayer.new
  @acomment_cmd_room             = AcommentMockRoom.new("Test Room")
  @acomment_cmd_target           = nil
  @acomment_cmd_target_name      = nil
  @acomment_cmd_comment          = nil
  @acomment_cmd_find_returns_nil = false

  # Stub $manager
  mgr = Object.new

  room_ref   = -> { @acomment_cmd_room }
  player_ref = @acomment_cmd_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref.call
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |_name, *_args|
    nil
  end

  $manager = mgr
end

Given('the acomment_cmd target is {string}') do |target|
  @acomment_cmd_target_name = target
end

Given('acomment_cmd comment is {string}') do |comment|
  @acomment_cmd_comment = comment
end

Given('acomment_cmd find_object returns nil') do
  @acomment_cmd_find_returns_nil = true
end

Given('acomment_cmd find_object returns an acomment_cmd object named {string}') do |name|
  @acomment_cmd_target = AcommentMockObject.new(name)
  @acomment_cmd_find_returns_nil = false
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the acomment_cmd action is invoked') do
  data = {
    target:  @acomment_cmd_target_name,
    comment: @acomment_cmd_comment
  }

  cmd = Aethyr::Core::Actions::Acomment::AcommentCommand.new(@acomment_cmd_player, **data)
  @acomment_cmd_command = cmd

  # Patch find_object on this instance to return our controlled target.
  target_ref = -> { @acomment_cmd_target }
  find_nil   = -> { @acomment_cmd_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil.call
    target_ref.call
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the acomment_cmd should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::Acomment::AcommentCommand.new(
    @acomment_cmd_player, target: "test", comment: "test comment"
  )
  assert_not_nil(cmd, "Expected AcommentCommand to be instantiated")
end

Then('the acomment_cmd player should see {string}') do |fragment|
  match = @acomment_cmd_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@acomment_cmd_player.messages.inspect}")
end

Then('the acomment_cmd object comment should be {string}') do |expected|
  target = @acomment_cmd_target
  assert_not_nil(target, "Expected a target object to exist")
  assert_equal(expected, target.comment,
    "Expected object.comment to be #{expected.inspect}, got: #{target.comment.inspect}")
end
