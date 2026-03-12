# frozen_string_literal: true
###############################################################################
# Step definitions for AdescCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/adesc'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AdescWorld
  attr_accessor :adesc_cmd_player, :adesc_cmd_room, :adesc_cmd_target,
                :adesc_cmd_object_ref, :adesc_cmd_inroom, :adesc_cmd_desc,
                :adesc_cmd_find_returns_nil, :adesc_cmd_command
end
World(AdescWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AdescMockPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize
    @container = "adesc_room_goid_1"
    @name      = "TestAdmin"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Room / generic object double with description attributes.
class AdescMockRoom
  attr_accessor :name, :show_in_look, :goid
  attr_reader :short_desc

  def initialize(name = "Test Room")
    @name          = name
    @goid          = "adesc_room_goid_1"
    @show_in_look  = nil
    @short_desc    = nil
  end

  def short_desc
    @short_desc
  end
end

# Separate object double for non-room targets.
class AdescMockObject
  attr_accessor :name, :show_in_look
  attr_reader :short_desc

  def initialize(name = "Test Object")
    @name          = name
    @show_in_look  = nil
    @short_desc    = nil
  end

  def short_desc
    @short_desc
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed adesc_cmd environment') do
  @adesc_cmd_player          = AdescMockPlayer.new
  @adesc_cmd_room            = AdescMockRoom.new("Test Room")
  @adesc_cmd_target          = nil
  @adesc_cmd_object_ref      = nil
  @adesc_cmd_inroom          = false
  @adesc_cmd_desc            = nil
  @adesc_cmd_find_returns_nil = false

  # Stub $manager
  mgr = Object.new

  room_ref   = -> { @adesc_cmd_room }
  target_ref = -> { @adesc_cmd_target }
  find_nil   = -> { @adesc_cmd_find_returns_nil }
  player_ref = @adesc_cmd_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref.call
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |_name, *_args|
    return nil if find_nil.call
    target_ref.call
  end

  $manager = mgr
end

Given('the adesc_cmd object reference is {string}') do |ref|
  @adesc_cmd_object_ref = ref
end

Given('adesc_cmd inroom is true') do
  @adesc_cmd_inroom = true
end

Given('adesc_cmd inroom is false') do
  @adesc_cmd_inroom = false
end

Given('adesc_cmd desc is nil') do
  @adesc_cmd_desc = nil
end

Given('adesc_cmd desc is {string}') do |desc|
  @adesc_cmd_desc = desc
end

Given('adesc_cmd find_object returns nil') do
  @adesc_cmd_find_returns_nil = true
end

Given('adesc_cmd find_object returns an adesc_cmd object named {string}') do |name|
  @adesc_cmd_target = AdescMockObject.new(name)
  @adesc_cmd_find_returns_nil = false
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the adesc_cmd action is invoked') do
  data = { object: @adesc_cmd_object_ref }
  data[:inroom] = @adesc_cmd_inroom if @adesc_cmd_inroom
  data[:desc]   = @adesc_cmd_desc

  cmd = Aethyr::Core::Actions::Adesc::AdescCommand.new(@adesc_cmd_player, **data)
  @adesc_cmd_command = cmd

  # Patch find_object on this instance to return our controlled target.
  target_ref = -> { @adesc_cmd_target }
  find_nil   = -> { @adesc_cmd_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil.call
    target_ref.call
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the adesc_cmd should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::Adesc::AdescCommand.new(@adesc_cmd_player, object: "test")
  assert_not_nil(cmd, "Expected AdescCommand to be instantiated")
end

Then('the adesc_cmd player should see {string}') do |fragment|
  match = @adesc_cmd_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@adesc_cmd_player.messages.inspect}")
end

Then('the adesc_cmd room show_in_look should be false') do
  assert_equal(false, @adesc_cmd_room.show_in_look,
    "Expected room.show_in_look to be false, got: #{@adesc_cmd_room.show_in_look.inspect}")
end

Then('the adesc_cmd room show_in_look should be {string}') do |expected|
  assert_equal(expected, @adesc_cmd_room.show_in_look,
    "Expected room.show_in_look to be #{expected.inspect}, got: #{@adesc_cmd_room.show_in_look.inspect}")
end

Then('the adesc_cmd object short_desc should be {string}') do |expected|
  target = @adesc_cmd_target
  assert_not_nil(target, "Expected a target object to exist")
  assert_equal(expected, target.short_desc,
    "Expected object.short_desc to be #{expected.inspect}, got: #{target.short_desc.inspect}")
end
