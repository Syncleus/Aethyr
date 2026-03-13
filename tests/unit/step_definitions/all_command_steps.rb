# frozen_string_literal: true
###############################################################################
# Step definitions for AllCommand action coverage.                             #
#                                                                              #
# These steps exercise every branch of                                         #
# lib/aethyr/core/actions/commands/all.rb to achieve >97% line coverage.       #
#                                                                              #
# All collaborators ($manager, find_board, player callbacks) are stubbed to    #
# isolate the command logic under test.                                        #
###############################################################################

require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/all'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module AllCommandWorld
  attr_accessor :all_player, :all_command, :all_board,
                :all_room, :all_find_board_result
end
World(AllCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal player double that records output.
class AllMockPlayer
  attr_accessor :container, :name, :word_wrap
  attr_reader   :messages

  def initialize(name, container)
    @name      = name
    @container = container
    @messages  = []
    @word_wrap = nil
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Minimal board double that supports list_latest.
class AllMockBoard
  attr_reader :goid

  def initialize(goid: :all_board_goid)
    @goid = goid
  end

  def list_latest(wordwrap, offset, limit)
    "Board listing (wrap=#{wordwrap}, offset=#{offset}, limit=#{limit.inspect})"
  end
end

# Minimal room double.
class AllMockRoom; end

###############################################################################
# Manager stub                                                                 #
###############################################################################
class AllMockManager
  def initialize
    @objects = {}
  end

  def register(goid, obj)
    @objects[goid] = obj
  end

  def get_object(goid)
    @objects[goid]
  end
end

###############################################################################
# Hooks – save / restore $manager around each scenario                         #
###############################################################################
Before do
  @all_saved_manager = $manager
end

After do
  $manager = @all_saved_manager if defined?(@all_saved_manager)
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed AllCommand environment') do
  self.all_room   = AllMockRoom.new
  self.all_player = AllMockPlayer.new('TestAllReader', :all_room_id)

  # Wire up $manager
  manager = AllMockManager.new
  manager.register(:all_room_id, all_room)
  $manager = manager

  # Defaults
  self.all_find_board_result = nil
  self.all_board             = nil
end

Given('the all board lookup will return nil') do
  self.all_find_board_result = nil
  self.all_board             = nil
end

Given('the all board lookup will return a board') do
  self.all_board = AllMockBoard.new(goid: :all_board_goid)
  self.all_find_board_result = all_board
end

Given('the all player word_wrap is set to {int}') do |wrap|
  all_player.word_wrap = wrap
end

Given('the all player word_wrap is nil') do
  all_player.word_wrap = nil
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the all command action is invoked') do
  self.all_command = Aethyr::Core::Actions::All::AllCommand.new(
    all_player
  )

  # Stub find_board on the command instance
  board_result = all_find_board_result
  all_command.define_singleton_method(:find_board) do |_event, _room|
    board_result
  end

  all_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the AllCommand should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::All::AllCommand.new(all_player)
  assert_not_nil(cmd, "Expected AllCommand to be instantiated")
end

Then('the all player should see {string}') do |expected|
  assert(
    all_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{all_player.messages.inspect}"
  )
end

Then('the all player should see the board listing') do
  assert(
    all_player.messages.any? { |m| m.include?("Board listing") },
    "Expected player output to contain board listing but got: #{all_player.messages.inspect}"
  )
end
