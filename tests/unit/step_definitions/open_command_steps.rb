# frozen_string_literal: true
###############################################################################
# Step definitions for OpenCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/open'
require 'aethyr/core/util/direction'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Monkey-patch: OpenCommand does not include Direction in its own hierarchy   #
# but the source calls expand_direction. Mix it in so the tests exercise the  #
# real code path.                                                             #
###############################################################################
unless Aethyr::Core::Actions::Open::OpenCommand.method_defined?(:expand_direction)
  Aethyr::Core::Actions::Open::OpenCommand.include(Aethyr::Direction)
end

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module OpenWorld
  attr_accessor :open_player, :open_room, :open_object, :open_command
end
World(OpenWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class OpenPlayer
  attr_accessor :container, :name, :goid

  def initialize
    @container = "room_goid_1"
    @name      = "TestOpener"
    @goid      = "player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def messages
    @messages
  end

  def search_inv(_name)
    nil
  end
end

# Mock game object that can optionally support :open
class OpenGameObject
  attr_accessor :name, :can_open
  attr_reader :open_called_with

  def initialize(name, opts = {})
    @name             = name
    @can_open         = opts.fetch(:can_open, false)
    @open_called_with = nil
  end

  def can?(sym)
    sym == :open ? @can_open : false
  end

  def open(event)
    @open_called_with = event
  end
end

# Mock room that can find registered objects
class OpenRoom
  def initialize
    @objects = {}
  end

  def register(name, obj)
    @objects[name] = obj
  end

  def find(_name)
    @objects.values.first
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed OpenCommand environment') do
  @open_player  = OpenPlayer.new
  @open_room    = OpenRoom.new
  @open_object  = nil

  room_ref   = @open_room
  player_ref = @open_player

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    goid == player_ref.container ? room_ref : nil
  end

  mgr.define_singleton_method(:find) do |name, container|
    container.respond_to?(:find) ? container.find(name) : nil
  end

  $manager = mgr
end

Given('the open target object is not found') do
  # Room has nothing registered and search_inv returns nil — object stays nil.
  @open_room = OpenRoom.new
  room_ref   = @open_room
  player_ref = @open_player

  $manager.define_singleton_method(:get_object) do |goid|
    goid == player_ref.container ? room_ref : nil
  end
end

Given('an open target object {string} that cannot be opened') do |name|
  @open_object = OpenGameObject.new(name, can_open: false)
  @open_room.register(name, @open_object)
end

Given('an open target object {string} that can be opened') do |name|
  @open_object = OpenGameObject.new(name, can_open: true)
  @open_room.register(name, @open_object)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the OpenCommand action is invoked') do
  object_name = @open_object ? @open_object.name : "nonexistent"
  # Pass player: in the data hash so that the `player` method accessor (used
  # on lines 16, 19, 21 of open.rb via OpenStruct) resolves to the mock.
  @open_command = Aethyr::Core::Actions::Open::OpenCommand.new(
    @open_player, object: object_name, player: @open_player
  )
  @open_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the open player should see {string}') do |fragment|
  match = @open_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@open_player.messages.inspect}")
end

Then('the open target object should have received open') do
  assert_not_nil(@open_object.open_called_with,
    "Expected object.open to have been called but it was not")
end
