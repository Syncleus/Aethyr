# frozen_string_literal: true
###############################################################################
# Step definitions for WhoCommand action coverage.                            #
#                                                                             #
# Covers lib/aethyr/core/actions/commands/who.rb lines 14-18, 21:            #
#   find_all, sort_by, room lookup, output building, and player.output call.  #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/who'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module WhoCommandWorld
  attr_accessor :who_player, :who_command, :who_find_all_result, :who_rooms
end
World(WhoCommandWorld)

###############################################################################
# Ensure the bare Player constant exists (who.rb references it on line 14)    #
###############################################################################
unless defined?(Player)
  Player = Class.new do
    attr_accessor :name
    def initialize(name = "DefaultPlayer")
      @name = name
    end
  end
end

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# A player stub that records every #output call.
class WhoTestPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "who_room_goid_1"
    @name      = "WhoTestPlayer"
    @goid      = "who_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg
  end
end

# A room stub with just a name.
class WhoTestRoom
  attr_accessor :name

  def initialize(name = "WhoTestRoom")
    @name = name
  end
end

# An online-player stub returned by find_all, with a container for room lookup.
class WhoTestOnlinePlayer
  attr_accessor :name, :container

  def initialize(name, container = nil)
    @name      = name
    @container = container
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed WhoCommand environment') do
  @who_player          = WhoTestPlayer.new
  @who_find_all_result = []
  @who_rooms           = {}   # container_id => WhoTestRoom | nil

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager with find_all and find
  who_world = self

  mgr = Object.new

  mgr.define_singleton_method(:find_all) do |_attrib, _klass|
    who_world.who_find_all_result
  end

  mgr.define_singleton_method(:find) do |container_id|
    who_world.who_rooms[container_id]
  end

  $manager = mgr
end

Given('the who manager find_all returns players {string} in rooms {string}') do |names_csv, rooms_csv|
  names = names_csv.split(',').map(&:strip)
  rooms = rooms_csv.split(',').map(&:strip)

  @who_find_all_result = names.each_with_index.map do |name, idx|
    container_id = "who_container_#{idx}"
    room = WhoTestRoom.new(rooms[idx] || "UnknownRoom")
    @who_rooms[container_id] = room
    WhoTestOnlinePlayer.new(name, container_id)
  end
end

Given('the who manager find_all returns no players') do
  @who_find_all_result = []
end

Given('the who manager find_all returns player {string} with no room') do |name|
  container_id = "who_container_nil"
  @who_rooms[container_id] = nil   # find will return nil
  @who_find_all_result = [WhoTestOnlinePlayer.new(name, container_id)]
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the WhoCommand action is invoked') do
  @who_command = Aethyr::Core::Actions::Who::WhoCommand.new(@who_player)
  @who_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the who player output should contain {string}') do |fragment|
  flat = @who_player.messages.flatten.map(&:to_s)
  match = flat.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected who player output containing #{fragment.inspect}, got: #{flat.inspect}")
end

Then('the who player output should have {int} entry') do |count|
  # The output is passed as an array to player.output; grab the last message array
  last_output = @who_player.messages.last
  assert(last_output.is_a?(Array),
    "Expected output to be an Array, got: #{last_output.class}")
  assert_equal(count, last_output.length,
    "Expected #{count} entry in output array, got #{last_output.length}: #{last_output.inspect}")
end
