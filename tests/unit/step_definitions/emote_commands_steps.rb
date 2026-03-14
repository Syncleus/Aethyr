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
require 'aethyr/core/actions/commands/emotes/ponder'
require 'aethyr/core/actions/commands/emotes/poke'
require 'aethyr/core/actions/commands/emotes/pet'
require 'aethyr/core/actions/commands/emotes/nod'
require 'aethyr/core/actions/commands/emotes/ew'
require 'aethyr/core/actions/commands/emotes/yes'
require 'aethyr/core/actions/commands/emotes/yawn'
require 'aethyr/core/actions/commands/emotes/shrug'
require 'aethyr/core/actions/commands/emotes/no'
require 'aethyr/core/actions/commands/emotes/hug'
require 'aethyr/core/actions/commands/emotes/skip'
require 'aethyr/core/actions/commands/emotes/back'
require 'aethyr/core/actions/commands/emotes/bow'
require 'aethyr/core/actions/commands/emotes/brb'
require 'aethyr/core/actions/commands/emotes/cheer'
require 'aethyr/core/actions/commands/emotes/curtsey'
require 'aethyr/core/actions/commands/emotes/snicker'
require 'aethyr/core/actions/commands/emotes/hm'
require 'aethyr/core/actions/commands/emotes/sigh'
require 'aethyr/core/actions/commands/emotes/smile'
require 'aethyr/core/actions/commands/emotes/bye'
require 'aethyr/core/actions/commands/emotes/hi'
require 'aethyr/core/actions/commands/emotes/wave'
require 'aethyr/core/actions/commands/emotes/huh'
require 'aethyr/core/actions/commands/emotes/er'
require 'aethyr/core/actions/commands/emotes/uh'
require 'aethyr/core/actions/commands/emotes/eh'
require 'aethyr/core/actions/commands/emotes/cry'

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
  'LaughCommand'  => Aethyr::Core::Actions::Laugh::LaughCommand,
  'BlushCommand'  => Aethyr::Core::Actions::Blush::BlushCommand,
  'FrownCommand'  => Aethyr::Core::Actions::Frown::FrownCommand,
  'GrinCommand'   => Aethyr::Core::Actions::Grin::GrinCommand,
  'AgreeCommand'  => Aethyr::Core::Actions::Agree::AgreeCommand,
  'PonderCommand' => Aethyr::Core::Actions::Ponder::PonderCommand,
  'PokeCommand'   => Aethyr::Core::Actions::Poke::PokeCommand,
  'PetCommand'    => Aethyr::Core::Actions::Pet::PetCommand,
  'NodCommand'    => Aethyr::Core::Actions::Nod::NodCommand,
  'EwCommand'     => Aethyr::Core::Actions::Ew::EwCommand,
  'YesCommand'    => Aethyr::Core::Actions::Yes::YesCommand,
  'YawnCommand'   => Aethyr::Core::Actions::Yawn::YawnCommand,
  'ShrugCommand'  => Aethyr::Core::Actions::Shrug::ShrugCommand,
  'NoCommand'     => Aethyr::Core::Actions::No::NoCommand,
  'HugCommand'    => Aethyr::Core::Actions::Hug::HugCommand,
  'SkipCommand'    => Aethyr::Core::Actions::Skip::SkipCommand,
  'BackCommand'    => Aethyr::Core::Actions::Back::BackCommand,
  'BowCommand'     => Aethyr::Core::Actions::Bow::BowCommand,
  'BrbCommand'     => Aethyr::Core::Actions::Brb::BrbCommand,
  'CheerCommand'   => Aethyr::Core::Actions::Cheer::CheerCommand,
  'CurtseyCommand' => Aethyr::Core::Actions::Curtsey::CurtseyCommand,
  'SnickerCommand' => Aethyr::Core::Actions::Snicker::SnickerCommand,
  'HmCommand'     => Aethyr::Core::Actions::Hm::HmCommand,
  'SighCommand'   => Aethyr::Core::Actions::Sigh::SighCommand,
  'SmileCommand'  => Aethyr::Core::Actions::Smile::SmileCommand,
  'ByeCommand'    => Aethyr::Core::Actions::Bye::ByeCommand,
  'HiCommand'     => Aethyr::Core::Actions::Hi::HiCommand,
  'WaveCommand'   => Aethyr::Core::Actions::Wave::WaveCommand,
  'HuhCommand'    => Aethyr::Core::Actions::Huh::HuhCommand,
  'ErCommand'     => Aethyr::Core::Actions::Er::ErCommand,
  'UhCommand'     => Aethyr::Core::Actions::Uh::UhCommand,
  'EhCommand'     => Aethyr::Core::Actions::Eh::EhCommand,
  'CryCommand'    => Aethyr::Core::Actions::Cry::CryCommand,
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

EMCMD_REGEX = '(LaughCommand|BlushCommand|FrownCommand|GrinCommand|AgreeCommand|PonderCommand|PokeCommand|PetCommand|NodCommand|EwCommand|YesCommand|YawnCommand|ShrugCommand|NoCommand|HugCommand|SkipCommand|BackCommand|BowCommand|BrbCommand|CheerCommand|CurtseyCommand|SnickerCommand|HmCommand|SighCommand|SmileCommand|ByeCommand|HiCommand|WaveCommand|HuhCommand|ErCommand|UhCommand|EhCommand|CryCommand)'

When(/^the #{EMCMD_REGEX} action is invoked with no target$/) do |cmd_name|
  klass = EMCMD_CLASSES.fetch(cmd_name)
  @emcmd_command = klass.new(@emcmd_player)
  @emcmd_command.action
end

When(/^the #{EMCMD_REGEX} action is invoked targeting self$/) do |cmd_name|
  # Register the player in the room so room.find returns the player.
  @emcmd_room.register(@emcmd_player.name, @emcmd_player)

  klass = EMCMD_CLASSES.fetch(cmd_name)
  @emcmd_command = klass.new(@emcmd_player, object: @emcmd_player.name)
  @emcmd_command.action
end

When(/^the #{EMCMD_REGEX} action is invoked targeting "([^"]*)"$/) do |cmd_name, target_name|
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

Then('the emcmd player direct output should include {string}') do |expected|
  match = @emcmd_player.messages.any? { |m| m.include?(expected) }
  assert(match,
    "Expected player direct output containing '#{expected}', got: #{@emcmd_player.messages.inspect}")
end

Then('the emcmd event to_deaf_other should be {string}') do |expected|
  event = @emcmd_room.events.last
  assert(event, 'No event was recorded on the room')
  actual = event[:to_deaf_other]
  assert(actual, 'to_deaf_other was not set on the event')
  assert_equal(expected, actual,
    "Expected to_deaf_other to be '#{expected}' but got: #{actual.inspect}")
end

Then('the emcmd room should not have received an event') do
  assert(@emcmd_room.events.empty?,
    "Expected room.out_event NOT to have been called but got: #{@emcmd_room.events.length} events")
end
