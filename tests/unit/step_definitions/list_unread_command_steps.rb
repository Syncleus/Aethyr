# frozen_string_literal: true
###############################################################################
# Step definitions for ListUnreadCommand action coverage.                      #
#                                                                              #
# These steps exercise every branch of                                         #
# lib/aethyr/core/actions/commands/list_unread.rb to achieve >97% line         #
# coverage.                                                                    #
#                                                                              #
# All collaborators ($manager, find_board, player callbacks) are stubbed to    #
# isolate the command logic under test.                                        #
###############################################################################

require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/list_unread'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module ListUnreadWorld
  attr_accessor :lunread_player, :lunread_command, :lunread_board,
                :lunread_room, :lunread_find_board_result
end
World(ListUnreadWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal info double that behaves like an OpenStruct for the boards attribute.
class LunreadMockInfo
  attr_accessor :boards
  def initialize(boards = nil)
    @boards = boards
  end
end

# Minimal player double that records output.
class LunreadMockPlayer
  attr_accessor :container, :name, :word_wrap
  attr_reader   :messages, :info

  def initialize(name, container)
    @name      = name
    @container = container
    @messages  = []
    @word_wrap = 80
    @info      = LunreadMockInfo.new(nil)
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Minimal board double that supports list_since and goid.
class LunreadMockBoard
  attr_reader :goid

  def initialize(goid: :lunread_board_goid)
    @goid = goid
  end

  def list_since(_last_read, _wrap)
    "Unread posts listing output"
  end
end

# Minimal room double.
class LunreadMockRoom; end

###############################################################################
# Manager stub                                                                 #
###############################################################################
class LunreadMockManager
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
  @lunread_saved_manager = $manager
end

After do
  $manager = @lunread_saved_manager if defined?(@lunread_saved_manager)
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed ListUnreadCommand environment') do
  self.lunread_room    = LunreadMockRoom.new
  self.lunread_player  = LunreadMockPlayer.new('TestReader', :lunread_room_id)

  # Wire up $manager
  manager = LunreadMockManager.new
  manager.register(:lunread_room_id, lunread_room)
  $manager = manager

  # Defaults
  self.lunread_find_board_result = nil
  self.lunread_board             = nil
end

Given('the lunread board lookup will return nil') do
  self.lunread_find_board_result = nil
  self.lunread_board             = nil
end

Given('the lunread board lookup will return a board') do
  self.lunread_board = LunreadMockBoard.new(goid: :lunread_board_goid)
  self.lunread_find_board_result = lunread_board
end

Given('the lunread player info boards is nil') do
  lunread_player.info.boards = nil
end

Given('the lunread player info boards already exists') do
  lunread_player.info.boards = { some_other_board: 1 }
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the lunread list unread command is invoked') do
  self.lunread_command = Aethyr::Core::Actions::ListUnread::ListUnreadCommand.new(
    lunread_player,
    player: lunread_player
  )

  # Stub find_board on the command instance (mixed in at runtime normally)
  board_result = lunread_find_board_result
  lunread_command.define_singleton_method(:find_board) do |_event, _room|
    board_result
  end

  lunread_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the lunread player should see {string}') do |expected|
  assert(
    lunread_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{lunread_player.messages.inspect}"
  )
end

Then('the lunread player info boards should be initialized') do
  assert_not_nil(
    lunread_player.info.boards,
    "Expected player.info.boards to be initialized but it is nil"
  )
  assert_kind_of(Hash, lunread_player.info.boards,
    "Expected player.info.boards to be a Hash")
end

Then('the lunread player should see the unread listing') do
  assert(
    lunread_player.messages.any? { |m| m.include?("Unread posts listing output") },
    "Expected player output to contain unread listing but got: #{lunread_player.messages.inspect}"
  )
end
