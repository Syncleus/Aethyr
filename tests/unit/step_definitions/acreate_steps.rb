# frozen_string_literal: true
###############################################################################
# Step definitions for AcreateCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/acreate'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AcreateWorld
  attr_accessor :acreate_player, :acreate_command, :acreate_room,
                :acreate_object_name, :acreate_name_val, :acreate_alt_names_val,
                :acreate_generic_val, :acreate_args_val, :acreate_room_nil,
                :acreate_created_object, :acreate_room_events
end
World(AcreateWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AcreatePlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "acreate_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "acreate_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def pronoun(type)
    case type
    when :possessive then "their"
    when :reflexive  then "themselves"
    else "they"
    end
  end
end

# Minimal created-object double
class AcreateCreatedObject
  attr_accessor :name

  def initialize
    @name = "a test item"
  end

  def to_s
    "#<AcreateCreatedObject name=#{@name}>"
  end
end

# Room double that records out_event calls
class AcreateRoom
  attr_reader :events

  def initialize
    @events = []
  end

  def out_event(event)
    @events << event
  end

  def name
    "Test Room"
  end

  def goid
    "acreate_room_goid_1"
  end
end

# Define top-level GameObject stub only if it doesn't already exist,
# so the bare `GameObject` reference in acreate.rb resolves correctly.
unless defined?(::GameObject)
  class ::GameObject; end
end

# Define top-level Player stub only if it doesn't already exist,
# inheriting from GameObject so `Player <= GameObject` is true.
unless defined?(::Player)
  class ::Player < ::GameObject; end
end

# A valid test subclass of GameObject for successful creation tests.
# The source capitalises only the first character of the input string, so
# "acreatetestitem" becomes "Acreatetestitem".  We define the constant to
# match that exact name.
unless defined?(::Acreatetestitem)
  class ::Acreatetestitem < ::GameObject
    attr_accessor :name
    def initialize
      @name = "a test item"
    end
    def to_s
      "#<Acreatetestitem name=#{@name}>"
    end
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AcreateCommand environment') do
  @acreate_player       = AcreatePlayer.new
  @acreate_object_name  = nil
  @acreate_name_val     = nil
  @acreate_alt_names_val = nil
  @acreate_generic_val  = nil
  @acreate_args_val     = nil
  @acreate_room_nil     = false
  @acreate_room_events  = nil

  @acreate_room = AcreateRoom.new

  # Build a stub manager
  room_ref   = @acreate_room
  player_ref = @acreate_player
  test_env   = self

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if test_env.acreate_room_nil
      nil
    elsif goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:create_object) do |klass, room, _third, args, vars|
    obj = AcreateCreatedObject.new
    obj.name = vars[:@name] if vars[:@name]
    test_env.acreate_created_object = obj
    obj
  end

  $manager = mgr

  # Ensure `log` is available as a no-op (parent classes may call it).
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end
end

Given('the acreate object is {string}') do |obj|
  @acreate_object_name = obj
end

Given('the acreate name is {string}') do |name|
  @acreate_name_val = name
end

Given('the acreate alt_names are {string}') do |alt_names|
  @acreate_alt_names_val = alt_names.split(',').map(&:strip)
end

Given('the acreate generic is {string}') do |generic|
  @acreate_generic_val = generic
end

Given('the acreate args are {string}') do |args|
  @acreate_args_val = args
end

Given('the acreate room is nil') do
  @acreate_room_nil = true
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AcreateCommand action is invoked') do
  data = {}
  data[:object]    = @acreate_object_name if @acreate_object_name
  data[:name]      = @acreate_name_val    if @acreate_name_val
  data[:alt_names] = @acreate_alt_names_val if @acreate_alt_names_val
  data[:generic]   = @acreate_generic_val if @acreate_generic_val
  data[:args]      = @acreate_args_val    if @acreate_args_val

  cmd = Aethyr::Core::Actions::Acreate::AcreateCommand.new(@acreate_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the acreate player should see {string}') do |fragment|
  match = @acreate_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected acreate player output containing #{fragment.inspect}, got: #{@acreate_player.messages.inspect}")
end

Then('the acreate room should have received an out_event') do
  assert(@acreate_room.events.length > 0,
    "Expected room to have received at least one out_event, but got none.")
end

Then('the acreate room should not have received an out_event') do
  assert_equal(0, @acreate_room.events.length,
    "Expected room to have received no out_event calls, but got #{@acreate_room.events.length}.")
end

Then('the acreate event to_player should contain {string}') do |fragment|
  event = @acreate_room.events.last
  assert(event, "Expected room to have received an event, but none found.")
  to_player = event[:to_player].to_s
  assert(to_player.include?(fragment),
    "Expected event :to_player to contain #{fragment.inspect}, got: #{to_player.inspect}")
end

Then('the acreate event to_other should contain {string}') do |fragment|
  event = @acreate_room.events.last
  assert(event, "Expected room to have received an event, but none found.")
  to_other = event[:to_other].to_s
  assert(to_other.include?(fragment),
    "Expected event :to_other to contain #{fragment.inspect}, got: #{to_other.inspect}")
end
