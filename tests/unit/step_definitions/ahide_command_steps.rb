# frozen_string_literal: true
###############################################################################
# Step definitions for AhideCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/ahide'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AhideWorld
  attr_accessor :ahide_player, :ahide_room, :ahide_target,
                :ahide_object_ref, :ahide_hide,
                :ahide_find_returns_nil, :ahide_command
end
World(AhideWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AhideMockPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize
    @container = "ahide_room_goid_1"
    @name      = "TestAdmin"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Room double.
class AhideMockRoom
  attr_accessor :name, :goid

  def initialize(name = "Test Room")
    @name = name
    @goid = "ahide_room_goid_1"
  end
end

# Generic object double with show_in_look attribute.
class AhideMockObject
  attr_accessor :name, :show_in_look

  def initialize(name = "Test Object", show_in_look = nil)
    @name          = name
    @show_in_look  = show_in_look
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed ahide_cmd environment') do
  @ahide_player          = AhideMockPlayer.new
  @ahide_room            = AhideMockRoom.new("Test Room")
  @ahide_target          = nil
  @ahide_object_ref      = nil
  @ahide_hide            = nil
  @ahide_find_returns_nil = false

  # Stub $manager
  mgr = Object.new

  room_ref   = -> { @ahide_room }
  player_ref = @ahide_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref.call
    else
      nil
    end
  end

  $manager = mgr
end

Given('the ahide_cmd object reference is {string}') do |ref|
  @ahide_object_ref = ref
end

Given('ahide_cmd find_object returns nil') do
  @ahide_find_returns_nil = true
end

Given('ahide_cmd find_object returns an object named {string}') do |name|
  @ahide_target = AhideMockObject.new(name)
  @ahide_find_returns_nil = false
end

Given('ahide_cmd find_object returns an object named {string} with show_in_look {string}') do |name, sil|
  @ahide_target = AhideMockObject.new(name, sil)
  @ahide_find_returns_nil = false
end

Given('ahide_cmd hide is true') do
  @ahide_hide = true
end

Given('ahide_cmd hide is not set') do
  @ahide_hide = nil
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the ahide_cmd action is invoked') do
  data = { object: @ahide_object_ref }
  data[:hide] = @ahide_hide if @ahide_hide

  cmd = Aethyr::Core::Actions::Ahide::AhideCommand.new(@ahide_player, **data)
  @ahide_command = cmd

  # Patch find_object on this instance to return our controlled target.
  target_ref = -> { @ahide_target }
  find_nil   = -> { @ahide_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil.call
    target_ref.call
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the ahide_cmd should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::Ahide::AhideCommand.new(@ahide_player, object: "test")
  assert_not_nil(cmd, "Expected AhideCommand to be instantiated")
end

Then('the ahide_cmd player should see {string}') do |fragment|
  match = @ahide_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@ahide_player.messages.inspect}")
end

Then('the ahide_cmd object show_in_look should be {string}') do |expected|
  assert_equal(expected, @ahide_target.show_in_look,
    "Expected object.show_in_look to be #{expected.inspect}, got: #{@ahide_target.show_in_look.inspect}")
end

Then('the ahide_cmd object show_in_look should be false') do
  assert_equal(false, @ahide_target.show_in_look,
    "Expected object.show_in_look to be false, got: #{@ahide_target.show_in_look.inspect}")
end
