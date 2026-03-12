# frozen_string_literal: true
################################################################################
# Step definitions for EmoteCommand action coverage.                           #
#                                                                              #
#   Covers:                                                                    #
#     • Constructor delegation (line 9)                                        #
#     • Room/player/action setup (lines 15-17)                                 #
#     • Punctuation auto-append (lines 19-20)                                  #
#     • $me substitution (lines 23-26)                                         #
#     • $target substitution with room.find (lines 27-33)                      #
#     • Target output with blind check (lines 35-37)                           #
#     • Room/player output for $target branch (lines 40-41)                    #
#     • Simple emote fallback (line 43)                                        #
#     • Show block: message_type, to_player, to_other, out_event (lines 46-50)#
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/emotes/emote'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module EmoteCommandWorld
  attr_accessor :emote_player, :emote_room, :emote_command,
                :emote_targets
end
World(EmoteCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# A minimal player stub with the interface used by EmoteCommand.
class EmoteTestPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize(name = 'TestPlayer')
    @name      = name
    @container = 'room_1'
    @messages  = []
  end

  def output(message, *_args)
    @messages << message.to_s
  end
end

# A minimal target stub that can optionally be blind.
class EmoteTestTarget
  attr_accessor :name
  attr_reader :messages

  def initialize(name, blind: false)
    @name     = name
    @blind    = blind
    @messages = []
  end

  def output(message, *_args)
    @messages << message.to_s
  end

  def can?(ability)
    ability == :blind && @blind
  end

  def blind?
    @blind
  end
end

# A minimal room stub that records output and resolves targets.
class EmoteTestRoom
  attr_reader :events, :output_messages

  def initialize
    @events          = []
    @objects         = {}
    @output_messages = []
  end

  def register(name, obj)
    @objects[name] = obj
  end

  def find(name)
    @objects[name]
  end

  def out_event(event)
    @events << event
  end

  def output(message, *_excluded)
    @output_messages << message.to_s
  end
end

# A minimal manager stub that returns a room for get_object.
class EmoteTestManager
  attr_accessor :room

  def initialize(room)
    @room = room
  end

  def get_object(_container_id)
    @room
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed EmoteCommand environment') do
  @emote_player  = EmoteTestPlayer.new('TestPlayer')
  @emote_room    = EmoteTestRoom.new
  @emote_targets = {}

  $manager = EmoteTestManager.new(@emote_room)
end

Given('a target named {string} exists in the emote room') do |name|
  target = EmoteTestTarget.new(name, blind: false)
  @emote_room.register(name, target)
  @emote_targets[name] = target
end

Given('a blind target named {string} exists in the emote room') do |name|
  target = EmoteTestTarget.new(name, blind: true)
  @emote_room.register(name, target)
  @emote_targets[name] = target
end

Given('a sighted target named {string} exists in the emote room') do |name|
  target = EmoteTestTarget.new(name, blind: false)
  @emote_room.register(name, target)
  @emote_targets[name] = target
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('the player emotes {string}') do |action_text|
  @emote_command = Aethyr::Core::Actions::Emote::EmoteCommand.new(
    @emote_player, show: action_text
  )
  @emote_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the emote event to_player should be {string}') do |expected|
  value = @emote_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert_equal(expected, value,
    "Expected to_player to be '#{expected}' but got: #{value.inspect}")
end

Then('the emote event to_other should be {string}') do |expected|
  value = @emote_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert_equal(expected, value,
    "Expected to_other to be '#{expected}' but got: #{value.inspect}")
end

Then('the emote event to_other should contain {string}') do |expected|
  value = @emote_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
    "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the emote event message_type should be chat') do
  assert_equal(:chat, @emote_command[:message_type],
    "Expected message_type to be :chat but got #{@emote_command[:message_type].inspect}")
end

Then('the emote room should receive the event') do
  assert(!@emote_room.events.empty?,
    'Expected room.out_event to have been called but no events were recorded')
  assert_equal(@emote_command, @emote_room.events.last,
    'The last event sent to the room should be the EmoteCommand itself')
end

Then('the emote target {string} should see {string}') do |name, expected|
  target = @emote_targets[name]
  assert(target, "No target registered with name '#{name}'")
  match = target.messages.any? { |m| m.include?(expected) }
  assert(match,
    "Expected target '#{name}' output to contain '#{expected}', got: #{target.messages.inspect}")
end

Then('the emote target {string} should not see anything') do |name|
  target = @emote_targets[name]
  assert(target, "No target registered with name '#{name}'")
  assert(target.messages.empty?,
    "Expected target '#{name}' to receive no output, but got: #{target.messages.inspect}")
end

Then('the emote room should receive output {string}') do |expected|
  match = @emote_room.output_messages.any? { |m| m.include?(expected) }
  assert(match,
    "Expected room output to contain '#{expected}', got: #{@emote_room.output_messages.inspect}")
end

Then('the emote player should see {string}') do |expected|
  match = @emote_player.messages.any? { |m| m.include?(expected) }
  assert(match,
    "Expected player output to contain '#{expected}', got: #{@emote_player.messages.inspect}")
end
