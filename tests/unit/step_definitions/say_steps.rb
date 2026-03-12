# frozen_string_literal: true
################################################################################
# Step-definitions validating Aethyr::Core::Actions::Say::SayCommand.          #
#                                                                              #
#   • SRP  – Each step performs exactly one behavioural assertion.              #
#   • OCP  – Production code remains untouched; seams are light-weight doubles.#
#   • LSP  – Test doubles honour the contracts expected by SayCommand.         #
#   • ISP  – Doubles implement *only* the interface actually exercised.        #
#   • DIP  – The concrete $manager global is replaced by a stub that conforms  #
#            to the abstract «get_object» dependency.                           #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/say'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for say scenarios                                               #
###############################################################################
module SayCommandWorld
  attr_accessor :say_player, :say_room, :say_command, :say_target_obj,
                :player_output_messages, :room_events
end
World(SayCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# A minimal player stub with just the interface used by SayCommand.
class SayTestPlayer
  attr_accessor :container, :name, :pronoun

  def initialize(name = 'TestPlayer')
    @name      = name
    @container = 'room_1'
    @pronoun   = 'he'
    @outputs   = []
  end

  def output(message, _newline = true)
    @outputs << message
  end

  def outputs
    @outputs
  end
end

# A minimal target object stub.
class SayTestTarget
  attr_accessor :name

  def initialize(name = 'Bob')
    @name = name
  end
end

# A minimal room stub that records events and can look up targets.
class SayTestRoom
  attr_reader :events

  def initialize
    @events    = []
    @objects   = {}
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
end

# A minimal manager stub that returns a room for get_object.
class SayTestManager
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
Given('a stubbed SayCommand environment') do
  @say_player  = SayTestPlayer.new('TestPlayer')
  @say_room    = SayTestRoom.new
  @say_target_obj = SayTestTarget.new('Bob')
  @say_room.register('Bob', @say_target_obj)

  $manager = SayTestManager.new(@say_room)

  @player_output_messages = @say_player.outputs
  @room_events            = @say_room.events
end

###############################################################################
# When                                                                         #
###############################################################################

When('the player says with no phrase') do
  @say_command = Aethyr::Core::Actions::Say::SayCommand.new(@say_player)
  @say_command.action
end

When('the player says {string} to an unknown target {string}') do |phrase, target_name|
  @say_command = Aethyr::Core::Actions::Say::SayCommand.new(
    @say_player, phrase: phrase, target: target_name
  )
  @say_command.action
end

When('the player says {string} targeting themselves') do |phrase|
  # Register the player in the room under a findable name
  @say_room.register('me', @say_player)
  @say_command = Aethyr::Core::Actions::Say::SayCommand.new(
    @say_player, phrase: phrase, target: 'me'
  )
  @say_command.action
end

When('the player says {string} with no target') do |phrase|
  @say_command = Aethyr::Core::Actions::Say::SayCommand.new(
    @say_player, phrase: phrase
  )
  @say_command.action
end

When('the player says {string} to target {string}') do |phrase, target_name|
  @say_command = Aethyr::Core::Actions::Say::SayCommand.new(
    @say_player, phrase: phrase, target: target_name
  )
  @say_command.action
end

When('the player says {string} with prefix {string} and no target') do |phrase, prefix|
  @say_command = Aethyr::Core::Actions::Say::SayCommand.new(
    @say_player, phrase: phrase, pre: prefix
  )
  @say_command.action
end

###############################################################################
# Then                                                                         #
###############################################################################

Then('the say player should see {string}') do |expected|
  assert(@player_output_messages.any? { |m| m.include?(expected) },
         "Expected player output to contain '#{expected}' but got: #{@player_output_messages.inspect}")
end

Then('the say event to_player should contain {string}') do |expected|
  value = @say_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert(value.include?(expected),
         "Expected to_player to contain '#{expected}' but got: #{value.inspect}")
end

Then('the say event to_other should contain {string}') do |expected|
  value = @say_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the say event to_target should contain {string}') do |expected|
  value = @say_command[:to_target]
  assert(value, 'to_target was not set on the event')
  assert(value.include?(expected),
         "Expected to_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the say event to_blind_target should contain {string}') do |expected|
  value = @say_command[:to_blind_target]
  assert(value, 'to_blind_target was not set on the event')
  assert(value.include?(expected),
         "Expected to_blind_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the say event to_blind_other should contain {string}') do |expected|
  value = @say_command[:to_blind_other]
  assert(value, 'to_blind_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_blind_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the say event to_deaf_target should contain {string}') do |expected|
  value = @say_command[:to_deaf_target]
  assert(value, 'to_deaf_target was not set on the event')
  assert(value.include?(expected),
         "Expected to_deaf_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the say event to_deaf_other should contain {string}') do |expected|
  value = @say_command[:to_deaf_other]
  assert(value, 'to_deaf_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_deaf_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the room should receive the event') do
  assert(!@room_events.empty?, 'Expected room.out_event to have been called but no events were recorded')
  assert_equal(@say_command, @room_events.last,
               'The last event sent to the room should be the SayCommand itself')
end

Then('the say event phrase should end with a period inside quotes') do
  to_player = @say_command[:to_player]
  assert(to_player, 'to_player was not set')
  # The phrase should be wrapped: <say>"...phrase."</say>
  assert(to_player.include?('."</say>'),
         "Expected phrase to end with period inside quotes, got: #{to_player.inspect}")
end

Then('the say event to_player should start with {string}') do |expected|
  value = @say_command[:to_player]
  assert(value, 'to_player was not set')
  assert(value.start_with?(expected),
         "Expected to_player to start with '#{expected}' but got: #{value.inspect}")
end

Then('the say event to_player should not start with {string}') do |expected|
  value = @say_command[:to_player]
  assert(value, 'to_player was not set')
  assert(!value.start_with?(expected),
         "Expected to_player NOT to start with '#{expected}' but got: #{value.inspect}")
end

Then('the say event phrase should contain {string}') do |expected|
  to_player = @say_command[:to_player]
  assert(to_player, 'to_player was not set')
  assert(to_player.include?(expected),
         "Expected phrase in to_player to contain '#{expected}' but got: #{to_player.inspect}")
end

Then('the say event message_type should be chat') do
  assert_equal(:chat, @say_command[:message_type],
               "Expected message_type to be :chat but got #{@say_command[:message_type].inspect}")
end
