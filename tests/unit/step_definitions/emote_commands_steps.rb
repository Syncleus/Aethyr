# frozen_string_literal: true
################################################################################
# Shared step definitions for the five specific emote commands:                #
#   LaughCommand, BlushCommand, FrownCommand, GrinCommand, AgreeCommand        #
#                                                                              #
# Each command follows the same EmoteAction/GenericEmote pattern with three    #
# branches: no_target, self_target, and target.  A single set of parameterised #
# steps covers all five emotes.                                                #
#                                                                              #
# Prefixes:  emcmd_  (instance vars)  /  EmCmd  (classes/modules)              #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/emotes/laugh'
require 'aethyr/core/actions/commands/emotes/blush'
require 'aethyr/core/actions/commands/emotes/frown'
require 'aethyr/core/actions/commands/emotes/grin'
require 'aethyr/core/actions/commands/emotes/agree'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state (uniquely prefixed)                    #
###############################################################################
module EmCmdWorld
  attr_accessor :emcmd_player, :emcmd_room, :emcmd_command, :emcmd_target
end
World(EmCmdWorld)

###############################################################################
# Monkey-patches required to exercise the GenericEmote DSL under test.        #
#                                                                             #
# 1. GenericEmote#target – return @object when called without a block so that #
#    `self.target.name` inside DSL blocks works correctly.                    #
# 2. GenericEmote#[] – delegate to @event so `self[:to_other]` works.         #
# 3. Event#has_key? – OpenStruct dropped has_key? in Ruby 3.x; the           #
#    make_emote guard requires it before calling room.out_event.              #
# 4. EmoteAction#log – stub out the logger (avoids Logger::Ultimate const).   #
###############################################################################
module Aethyr
  module Extend
    class EmoteAction
      class GenericEmote
        unless method_defined?(:_emcmd_target_patched)
          alias_method :_emcmd_orig_target, :target

          def target(&block)
            return @object unless block
            _emcmd_orig_target(&block)
          end

          def [](key)
            @event[key]
          end

          def _emcmd_target_patched; true; end
        end
      end

      # Silence the logger call inside make_emote.
      def log(*_args); end
    end
  end
end

class Event
  unless method_defined?(:has_key?)
    def has_key?(key)
      @table.has_key?(key)
    end
  end
end

# Provide Logger::Ultimate so the log call inside make_emote does not explode.
unless defined?(Logger::Ultimate)
  require 'logger' unless defined?(Logger)
  Logger.const_set(:Ultimate, 0)
end

###############################################################################
# Lightweight test doubles (all prefixed with EmCmd)                          #
###############################################################################

class EmCmdMockPlayer
  attr_accessor :container, :name
  attr_reader   :messages

  def initialize(name = 'TestPlayer')
    @name      = name
    @container = 'emcmd_room_1'
    @messages  = []
  end

  def output(message, *_args)
    @messages << message.to_s
  end

  def pronoun(type = nil)
    case type
    when :reflexive  then 'himself'
    when :possessive then 'his'
    when :objective  then 'him'
    else 'he'
    end
  end

  def search_inv(_name)
    nil
  end
end

class EmCmdMockTarget
  attr_accessor :name
  attr_reader   :messages

  def initialize(name)
    @name     = name
    @messages = []
  end

  def output(message, *_args)
    @messages << message.to_s
  end

  def pronoun(type = nil)
    case type
    when :reflexive  then 'himself'
    when :possessive then 'his'
    when :objective  then 'him'
    else 'he'
    end
  end
end

class EmCmdMockRoom
  attr_reader :events

  def initialize
    @events  = []
    @objects = {}
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

class EmCmdMockManager
  attr_accessor :room

  def initialize(room)
    @room = room
  end

  def get_object(_container_id)
    @room
  end
end

###############################################################################
# Command class lookup helper                                                 #
###############################################################################
EMCMD_CLASSES = {
  'LaughCommand' => Aethyr::Core::Actions::Laugh::LaughCommand,
  'BlushCommand' => Aethyr::Core::Actions::Blush::BlushCommand,
  'FrownCommand' => Aethyr::Core::Actions::Frown::FrownCommand,
  'GrinCommand'  => Aethyr::Core::Actions::Grin::GrinCommand,
  'AgreeCommand' => Aethyr::Core::Actions::Agree::AgreeCommand,
}.freeze

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed emote commands environment') do
  @emcmd_player = EmCmdMockPlayer.new('TestPlayer')
  @emcmd_room   = EmCmdMockRoom.new
  @emcmd_target = nil

  $manager = EmCmdMockManager.new(@emcmd_room)
end

Given('an emcmd target named {string} exists in the room') do |name|
  @emcmd_target = EmCmdMockTarget.new(name)
  @emcmd_room.register(name, @emcmd_target)
end

###############################################################################
# When steps                                                                  #
###############################################################################

When(/^the (LaughCommand|BlushCommand|FrownCommand|GrinCommand|AgreeCommand) action is invoked with no target$/) do |cmd_name|
  klass = EMCMD_CLASSES.fetch(cmd_name)
  @emcmd_command = klass.new(@emcmd_player)
  @emcmd_command.action
end

When(/^the (LaughCommand|BlushCommand|FrownCommand|GrinCommand|AgreeCommand) action is invoked targeting self$/) do |cmd_name|
  # Register the player in the room so room.find returns the player.
  @emcmd_room.register(@emcmd_player.name, @emcmd_player)

  klass = EMCMD_CLASSES.fetch(cmd_name)
  @emcmd_command = klass.new(@emcmd_player, object: @emcmd_player.name)
  @emcmd_command.action
end

When(/^the (LaughCommand|BlushCommand|FrownCommand|GrinCommand|AgreeCommand) action is invoked targeting "([^"]*)"$/) do |cmd_name, target_name|
  klass = EMCMD_CLASSES.fetch(cmd_name)
  @emcmd_command = klass.new(@emcmd_player, object: target_name)
  @emcmd_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the emcmd player should see {string}') do |expected|
  event = @emcmd_room.events.last
  assert(event, 'Expected room to have received an event but none were recorded')
  actual = event[:to_player]
  assert(actual, 'to_player was not set on the event')
  assert_equal(expected, actual,
    "Expected to_player to be '#{expected}' but got: #{actual.inspect}")
end

Then('the emcmd room should have received an event') do
  assert(!@emcmd_room.events.empty?,
    'Expected room.out_event to have been called but no events were recorded')
end

Then('the emcmd event to_other should be {string}') do |expected|
  event = @emcmd_room.events.last
  assert(event, 'No event was recorded on the room')
  actual = event[:to_other]
  assert(actual, 'to_other was not set on the event')
  assert_equal(expected, actual,
    "Expected to_other to be '#{expected}' but got: #{actual.inspect}")
end

Then('the emcmd event to_target should be {string}') do |expected|
  event = @emcmd_room.events.last
  assert(event, 'No event was recorded on the room')
  actual = event[:to_target]
  assert(actual, 'to_target was not set on the event')
  assert_equal(expected, actual,
    "Expected to_target to be '#{expected}' but got: #{actual.inspect}")
end
