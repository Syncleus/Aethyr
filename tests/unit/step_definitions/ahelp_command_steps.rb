# frozen_string_literal: true
###############################################################################
# Step definitions for AhelpCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AhelpWorld
  attr_accessor :ahelp_player, :ahelp_room, :ahelp_manager, :ahelp_command
end
World(AhelpWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AhelpMockPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize
    @container = "ahelp_room_goid_1"
    @name      = "TestAdmin"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Room double.
class AhelpMockRoom
  attr_accessor :name, :goid

  def initialize(name = "Test Room")
    @name = name
    @goid = "ahelp_room_goid_1"
  end
end

###############################################################################
# Ensure Generic module has a .help stub and tracking.                        #
# This is additive: if Generic already exists (e.g. from deleteme steps) we  #
# only add the methods we need without clobbering existing ones.              #
###############################################################################
module Generic; end unless defined?(Generic)

Generic.instance_variable_set(:@help_calls, []) unless Generic.instance_variable_defined?(:@help_calls)

unless Generic.respond_to?(:help)
  Generic.define_singleton_method(:help) do |command, player, room|
    @help_calls << { command: command, player: player, room: room }
  end
end

unless Generic.respond_to?(:help_calls)
  Generic.define_singleton_method(:help_calls) do
    @help_calls
  end
end

unless Generic.respond_to?(:ahelp_reset!)
  Generic.define_singleton_method(:ahelp_reset!) do
    @help_calls = []
  end
end

###############################################################################
# Now load the actual command under test                                      #
###############################################################################
require 'aethyr/core/actions/commands/ahelp'

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed ahelp_cmd environment') do
  @ahelp_player = AhelpMockPlayer.new
  @ahelp_room   = AhelpMockRoom.new("Test Room")

  # Stub $manager
  mgr = Object.new

  room_ref   = -> { @ahelp_room }
  player_ref = @ahelp_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref.call
    else
      nil
    end
  end

  $manager = mgr
  @ahelp_manager = mgr

  Generic.ahelp_reset!
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the ahelp_cmd action is invoked') do
  @ahelp_command = Aethyr::Core::Actions::Ahelp::AhelpCommand.new(@ahelp_player)
  @ahelp_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the ahelp_cmd should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::Ahelp::AhelpCommand.new(@ahelp_player)
  assert_not_nil(cmd, "Expected AhelpCommand to be instantiated")
end

Then('the ahelp_cmd Generic.help should have been called') do
  assert(!Generic.help_calls.empty?,
    "Expected Generic.help to have been called, but it was not.")
end

Then('the ahelp_cmd Generic.help should have received the player') do
  call = Generic.help_calls.last
  assert_not_nil(call, "Expected Generic.help to have been called")
  assert_equal(@ahelp_player, call[:player],
    "Expected Generic.help to receive the player, got: #{call[:player].inspect}")
end

Then('the ahelp_cmd Generic.help should have received the room') do
  call = Generic.help_calls.last
  assert_not_nil(call, "Expected Generic.help to have been called")
  assert_equal(@ahelp_room, call[:room],
    "Expected Generic.help to receive the room, got: #{call[:room].inspect}")
end
