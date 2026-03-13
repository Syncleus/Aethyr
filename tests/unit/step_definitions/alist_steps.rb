# frozen_string_literal: true
###############################################################################
# Step definitions for AlistCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/alist'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AlistWorld
  attr_accessor :alist_player, :alist_match, :alist_attrib,
                :alist_find_all_result
end
World(AlistWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AlistPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "alist_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "alist_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Simple game object double for results.
class AlistGameObjectDouble
  attr_reader :name, :goid

  def initialize(name, goid)
    @name = name
    @goid = goid
  end

  def to_s
    "#{@name}(#{@goid})"
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AlistCommand environment') do
  @alist_player          = AlistPlayer.new
  @alist_match           = nil
  @alist_attrib          = nil
  @alist_find_all_result = []

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: "alist_room_goid_1")

  # Build a stub manager
  player_ref  = @alist_player
  alist_world = self

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  mgr.define_singleton_method(:find_all) do |attrib, query|
    alist_world.alist_find_all_result
  end

  $manager = mgr

  # Set up $LOG so the `log` method doesn't crash
  unless $LOG
    log_double = Object.new
    log_double.define_singleton_method(:add) do |*args, **kwargs|
      # no-op
    end
    log_double.define_singleton_method(:dump) { }
    $LOG = log_double
  end
end

Given('the alist match is not set') do
  @alist_match  = nil
  @alist_attrib = nil
end

Given('the alist match is {string} with attrib {string}') do |match, attrib|
  @alist_match  = match
  @alist_attrib = attrib
end

Given('the alist manager find_all returns objects') do
  @alist_find_all_result = [
    AlistGameObjectDouble.new("TestObject1", "goid_1"),
    AlistGameObjectDouble.new("TestObject2", "goid_2")
  ]
end

Given('the alist manager find_all returns no objects') do
  @alist_find_all_result = []
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AlistCommand action is invoked') do
  data = {}
  data[:match]  = @alist_match  unless @alist_match.nil?
  data[:attrib] = @alist_attrib unless @alist_attrib.nil?

  cmd = Aethyr::Core::Actions::Alist::AlistCommand.new(@alist_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the alist player should see {string}') do |fragment|
  match = @alist_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected alist player output containing #{fragment.inspect}, got: #{@alist_player.messages.inspect}")
end
