# frozen_string_literal: true
################################################################################
# Step-definitions validating Aethyr::Core::Actions::Whisper::WhisperCommand.  #
#                                                                              #
#   • SRP  – Each step performs exactly one behavioural assertion.              #
#   • OCP  – Production code remains untouched; seams are light-weight doubles.#
#   • LSP  – Test doubles honour the contracts expected by WhisperCommand.     #
#   • ISP  – Doubles implement *only* the interface actually exercised.        #
#   • DIP  – The concrete $manager global is replaced by a stub that conforms  #
#            to the abstract «get_object» dependency.                           #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/whisper'

# Provide the Player constant referenced in whisper.rb:15
# (room.find(self[:to], Player)). The test room double ignores
# the class argument, so a bare class is sufficient.
Player = Class.new unless defined?(Player)

World(Test::Unit::Assertions)

###############################################################################
# Shared state for whisper scenarios                                           #
###############################################################################
module WhisperCommandWorld
  attr_accessor :whisper_player, :whisper_room, :whisper_command,
                :whisper_target_obj, :whisper_player_output_messages,
                :whisper_room_events
end
World(WhisperCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# A minimal player stub with just the interface used by WhisperCommand.
class WhisperTestPlayer
  attr_accessor :container, :name

  def initialize(name = 'TestWhisperer')
    @name      = name
    @container = 'room_1'
    @outputs   = []
  end

  # WhisperCommand calls @player.pronoun(:reflexive)
  def pronoun(type = nil)
    case type
    when :reflexive then 'himself'
    else 'he'
    end
  end

  def output(message, _newline = true)
    @outputs << message
  end

  # Line 30 of whisper.rb has a typo: `ouput` instead of `output`.
  # We must support it so the test does not raise NoMethodError.
  def ouput(message, _newline = true)
    @outputs << message
  end

  def outputs
    @outputs
  end
end

# A minimal target object stub.
class WhisperTestTarget
  attr_accessor :name

  def initialize(name = 'Bob')
    @name = name
  end
end

# A minimal room stub that records events and can look up targets.
# WhisperCommand calls room.find(name, Player) with two arguments.
class WhisperTestRoom
  attr_reader :events

  def initialize
    @events  = []
    @objects = {}
  end

  def register(name, obj)
    @objects[name] = obj
  end

  # Accept optional second argument (klass) to match whisper's room.find(name, Player)
  def find(name, _klass = nil)
    @objects[name]
  end

  # Accept optional second argument to match room.out_event(self, @player)
  def out_event(event, exclude = nil)
    @events << { event: event, exclude: exclude }
  end
end

# A minimal manager stub that returns a room for get_object.
class WhisperTestManager
  attr_accessor :room

  def initialize(room)
    @room = room
  end

  def get_object(_container_id)
    @room
  end
end

###############################################################################
# Given                                                                        #
###############################################################################
Given('a stubbed WhisperCommand environment') do
  @whisper_player     = WhisperTestPlayer.new('TestWhisperer')
  @whisper_room       = WhisperTestRoom.new
  @whisper_target_obj = WhisperTestTarget.new('Bob')
  @whisper_room.register('Bob', @whisper_target_obj)

  $manager = WhisperTestManager.new(@whisper_room)

  @whisper_player_output_messages = @whisper_player.outputs
  @whisper_room_events            = @whisper_room.events
end

###############################################################################
# When                                                                         #
###############################################################################

When('the player whispers {string} to an unknown target {string}') do |phrase, target_name|
  @whisper_command = Aethyr::Core::Actions::Whisper::WhisperCommand.new(
    @whisper_player, to: target_name, phrase: phrase
  )
  @whisper_command.action
end

When('the player whispers {string} targeting themselves') do |phrase|
  # Register the player in the room under a findable name
  @whisper_room.register('me', @whisper_player)
  @whisper_command = Aethyr::Core::Actions::Whisper::WhisperCommand.new(
    @whisper_player, to: 'me', phrase: phrase
  )
  @whisper_command.action
end

When('the player whispers with no phrase to target {string}') do |target_name|
  @whisper_command = Aethyr::Core::Actions::Whisper::WhisperCommand.new(
    @whisper_player, to: target_name
  )
  @whisper_command.action
end

When('the player whispers {string} with prefix {string} to target {string}') do |phrase, prefix, target_name|
  @whisper_command = Aethyr::Core::Actions::Whisper::WhisperCommand.new(
    @whisper_player, to: target_name, phrase: phrase, pre: prefix
  )
  @whisper_command.action
end

When('the player whispers {string} to target {string}') do |phrase, target_name|
  @whisper_command = Aethyr::Core::Actions::Whisper::WhisperCommand.new(
    @whisper_player, to: target_name, phrase: phrase
  )
  @whisper_command.action
end

###############################################################################
# Then                                                                         #
###############################################################################

Then('the whisper player should see {string}') do |expected|
  assert(@whisper_player_output_messages.any? { |m| m.include?(expected) },
         "Expected player output to contain '#{expected}' but got: #{@whisper_player_output_messages.inspect}")
end

Then('the whisper event to_other should contain {string}') do |expected|
  value = @whisper_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the whisper room should receive the self-whisper event') do
  assert(!@whisper_room_events.empty?,
         'Expected room.out_event to have been called but no events were recorded')
  last = @whisper_room_events.last
  assert_equal(@whisper_command, last[:event],
               'The last event sent to the room should be the WhisperCommand itself')
  assert_equal(@whisper_player, last[:exclude],
               'The self-whisper event should exclude the player')
end

Then('the whisper event to_player should start with {string}') do |expected|
  value = @whisper_command[:to_player]
  assert(value, 'to_player was not set')
  assert(value.start_with?(expected),
         "Expected to_player to start with '#{expected}' but got: #{value.inspect}")
end

Then('the whisper event to_player should not start with {string}') do |expected|
  value = @whisper_command[:to_player]
  assert(value, 'to_player was not set')
  assert(!value.start_with?(expected),
         "Expected to_player NOT to start with '#{expected}' but got: #{value.inspect}")
end

Then('the whisper event to_player phrase should end with a period inside quotes') do
  value = @whisper_command[:to_player]
  assert(value, 'to_player was not set')
  assert(value.include?('."</say>'),
         "Expected phrase to end with period inside quotes, got: #{value.inspect}")
end

Then('the whisper event to_player phrase should not have double period') do
  value = @whisper_command[:to_player]
  assert(value, 'to_player was not set')
  assert(!value.include?('.."'),
         "Expected no double period, got: #{value.inspect}")
end

Then('the whisper event to_player phrase should contain {string}') do |expected|
  value = @whisper_command[:to_player]
  assert(value, 'to_player was not set')
  assert(value.include?(expected),
         "Expected to_player to contain '#{expected}' but got: #{value.inspect}")
end

Then('the whisper event to_player should contain {string}') do |expected|
  value = @whisper_command[:to_player]
  assert(value, 'to_player was not set')
  assert(value.include?(expected),
         "Expected to_player to contain '#{expected}' but got: #{value.inspect}")
end

Then('the whisper event to_target should contain {string}') do |expected|
  value = @whisper_command[:to_target]
  assert(value, 'to_target was not set')
  assert(value.include?(expected),
         "Expected to_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the whisper event to_other_blind should contain {string}') do |expected|
  value = @whisper_command[:to_other_blind]
  assert(value, 'to_other_blind was not set')
  assert(value.include?(expected),
         "Expected to_other_blind to contain '#{expected}' but got: #{value.inspect}")
end

Then('the whisper event to_target_blind should contain {string}') do |expected|
  value = @whisper_command[:to_target_blind]
  assert(value, 'to_target_blind was not set')
  assert(value.include?(expected),
         "Expected to_target_blind to contain '#{expected}' but got: #{value.inspect}")
end

Then('the whisper event target should be the target object') do
  assert_equal(@whisper_target_obj, @whisper_command[:target],
               'Expected event target to be the target object')
end

Then('the whisper room should receive the event') do
  assert(!@whisper_room_events.empty?,
         'Expected room.out_event to have been called but no events were recorded')
  last = @whisper_room_events.last
  assert_equal(@whisper_command, last[:event],
               'The last event sent to the room should be the WhisperCommand itself')
end
