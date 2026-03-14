# frozen_string_literal: true
###############################################################################
# Step definitions for AlearnCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/alearn'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AlearnWorld
  attr_accessor :alearn_player, :alearn_room, :alearn_command,
                :alearn_action_error
end
World(AlearnWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AlearnMockPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize
    @container = "alearn_room_goid_1"
    @name      = "TestAdmin"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Room double.
class AlearnMockRoom
  attr_accessor :name, :goid

  def initialize(name = "Test Room")
    @name = name
    @goid = "alearn_room_goid_1"
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed alearn_cmd environment') do
  @alearn_player       = AlearnMockPlayer.new
  @alearn_room         = AlearnMockRoom.new("Test Room")
  @alearn_action_error = nil

  # Stub $manager
  mgr = Object.new

  room_ref   = -> { @alearn_room }
  player_ref = @alearn_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref.call
    else
      nil
    end
  end

  $manager = mgr
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the alearn_cmd action is invoked') do
  cmd = Aethyr::Core::Actions::Alearn::AlearnCommand.new(@alearn_player)
  @alearn_command = cmd

  begin
    cmd.action
  rescue => e
    @alearn_action_error = e
  end
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the alearn_cmd should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::Alearn::AlearnCommand.new(@alearn_player)
  assert_not_nil(cmd, "Expected AlearnCommand to be instantiated")
end

Then('the alearn_cmd action should complete without error') do
  assert_nil(@alearn_action_error,
    "Expected action to complete without error, but got: #{@alearn_action_error.inspect}")
  assert_not_nil(@alearn_command, "Expected command to have been created")
end
