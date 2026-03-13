# frozen_string_literal: true
###############################################################################
# Step definitions for CloseCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/close'
require 'aethyr/core/util/direction'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Monkey-patch: CloseCommand does not include Direction in its own hierarchy  #
# but the source calls expand_direction. Mix it in so the tests exercise the  #
# real code path.                                                             #
###############################################################################
unless Aethyr::Core::Actions::Close::CloseCommand.method_defined?(:expand_direction)
  Aethyr::Core::Actions::Close::CloseCommand.include(Aethyr::Direction)
end

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module CloseWorld
  attr_accessor :close_player, :close_room, :close_object, :close_command
end
World(CloseWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class ClosePlayer
  attr_accessor :container, :name, :goid

  def initialize
    @container = "room_goid_1"
    @name      = "TestCloser"
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
class CloseGameObject
  attr_accessor :name, :can_open
  attr_reader :close_called_with

  def initialize(name, opts = {})
    @name              = name
    @can_open          = opts.fetch(:can_open, false)
    @close_called_with = nil
  end

  def can?(sym)
    sym == :open ? @can_open : false
  end

  def close(event)
    @close_called_with = event
  end
end

# Mock room that can find registered objects
class CloseRoom
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
Given('a stubbed CloseCommand environment') do
  @close_player  = ClosePlayer.new
  @close_room    = CloseRoom.new
  @close_object  = nil

  room_ref   = @close_room
  player_ref = @close_player

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    goid == player_ref.container ? room_ref : nil
  end

  mgr.define_singleton_method(:find) do |name, container|
    container.respond_to?(:find) ? container.find(name) : nil
  end

  $manager = mgr
end

Given('the close target object is not found') do
  # Room has nothing registered and search_inv returns nil — object stays nil.
  @close_room = CloseRoom.new
  room_ref   = @close_room
  player_ref = @close_player

  $manager.define_singleton_method(:get_object) do |goid|
    goid == player_ref.container ? room_ref : nil
  end
end

Given('a close target object {string} that cannot be opened') do |name|
  @close_object = CloseGameObject.new(name, can_open: false)
  @close_room.register(name, @close_object)
end

Given('a close target object {string} that can be opened') do |name|
  @close_object = CloseGameObject.new(name, can_open: true)
  @close_room.register(name, @close_object)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the CloseCommand action is invoked') do
  object_name = @close_object ? @close_object.name : "nonexistent"
  @close_command = Aethyr::Core::Actions::Close::CloseCommand.new(
    @close_player, object: object_name
  )
  @close_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the close player should see {string}') do |fragment|
  match = @close_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@close_player.messages.inspect}")
end

Then('the close target object should have received close') do
  assert_not_nil(@close_object.close_called_with,
    "Expected object.close to have been called but it was not")
end
