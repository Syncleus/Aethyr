# frozen_string_literal: true
###############################################################################
# Step definitions for LatestNewsCommand action coverage.                      #
#                                                                              #
# These steps exercise every branch of                                         #
# lib/aethyr/core/actions/commands/latest_news.rb to achieve >97% line         #
# coverage.                                                                    #
#                                                                              #
# All collaborators ($manager, find_board, player callbacks) are stubbed to    #
# isolate the command logic under test.                                        #
###############################################################################

require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/latest_news'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module LatestNewsWorld
  attr_accessor :lnews_player, :lnews_command, :lnews_board,
                :lnews_room, :lnews_find_board_result,
                :lnews_offset, :lnews_limit
end
World(LatestNewsWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal player double that records output.
class LnewsMockPlayer
  attr_accessor :container, :name, :word_wrap, :page_height
  attr_reader   :messages

  def initialize(name, container)
    @name        = name
    @container   = container
    @messages    = []
    @word_wrap   = nil
    @page_height = nil
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Minimal board double (NOT a Newsboard) that records list_latest calls.
class LnewsMockBoard
  attr_reader :list_latest_calls

  def initialize
    @list_latest_calls = []
  end

  def list_latest(wordwrap, offset, limit)
    @list_latest_calls << { wordwrap: wordwrap, offset: offset, limit: limit }
    "Latest news listing output"
  end
end

# Define a top-level Newsboard class for the is_a? check if not already defined.
unless defined?(Newsboard)
  class Newsboard; end
end

# A board double that IS a Newsboard.
class LnewsMockNewsboard < Newsboard
  attr_reader :list_latest_calls

  def initialize
    @list_latest_calls = []
  end

  def list_latest(wordwrap, offset, limit)
    @list_latest_calls << { wordwrap: wordwrap, offset: offset, limit: limit }
    "Latest news listing output"
  end
end

# Minimal room double.
class LnewsMockRoom; end

###############################################################################
# Manager stub                                                                 #
###############################################################################
class LnewsMockManager
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
  @lnews_saved_manager = $manager
end

After do
  $manager = @lnews_saved_manager if defined?(@lnews_saved_manager)
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed LatestNewsCommand environment') do
  self.lnews_room    = LnewsMockRoom.new
  self.lnews_player  = LnewsMockPlayer.new('TestReader', :lnews_room_id)

  # Wire up $manager
  manager = LnewsMockManager.new
  manager.register(:lnews_room_id, lnews_room)
  $manager = manager

  # Defaults
  self.lnews_find_board_result = nil
  self.lnews_board             = nil
  self.lnews_offset            = nil
  self.lnews_limit             = nil
end

Given('the lnews board lookup will return nil') do
  self.lnews_find_board_result = nil
  self.lnews_board             = nil
end

Given('the lnews board lookup will return a non-newsboard board') do
  self.lnews_board = LnewsMockBoard.new
  self.lnews_find_board_result = lnews_board
end

Given('the lnews board lookup will return a newsboard') do
  self.lnews_board = LnewsMockNewsboard.new
  self.lnews_find_board_result = lnews_board
end

Given('the lnews command has offset {int} and limit {int}') do |offset, limit|
  self.lnews_offset = offset
  self.lnews_limit  = limit
end

Given('the lnews player has word_wrap {int} and page_height {int}') do |ww, ph|
  lnews_player.word_wrap   = ww
  lnews_player.page_height = ph
end

Given('the lnews player has no word_wrap and page_height {int}') do |ph|
  lnews_player.word_wrap   = nil
  lnews_player.page_height = ph
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the lnews latest news command is invoked') do
  cmd_args = { player: lnews_player }
  cmd_args[:offset] = lnews_offset if lnews_offset
  cmd_args[:limit]  = lnews_limit  if lnews_limit

  self.lnews_command = Aethyr::Core::Actions::LatestNews::LatestNewsCommand.new(
    lnews_player,
    **cmd_args
  )

  # Stub find_board on the command instance
  board_result = lnews_find_board_result
  lnews_command.define_singleton_method(:find_board) do |_event, _room|
    board_result
  end

  lnews_command.action
end

When('the lnews latest news command is invoked with no offset or limit') do
  self.lnews_command = Aethyr::Core::Actions::LatestNews::LatestNewsCommand.new(
    lnews_player,
    player: lnews_player
  )

  # Stub find_board on the command instance
  board_result = lnews_find_board_result
  lnews_command.define_singleton_method(:find_board) do |_event, _room|
    board_result
  end

  lnews_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the lnews player should see {string}') do |expected|
  assert(
    lnews_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{lnews_player.messages.inspect}"
  )
end

Then('the lnews player should see the board listing') do
  assert(
    lnews_player.messages.any? { |m| m.include?("Latest news listing output") },
    "Expected player output to contain board listing but got: #{lnews_player.messages.inspect}"
  )
end

Then('the lnews board should have received list_latest with wordwrap {int} offset {int} limit {int}') do |ww, offset, limit|
  calls = lnews_board.list_latest_calls
  assert(!calls.empty?, "Expected board.list_latest to have been called but it was not")
  last_call = calls.last
  assert_equal(ww,     last_call[:wordwrap], "Expected wordwrap #{ww} but got #{last_call[:wordwrap]}")
  assert_equal(offset, last_call[:offset],   "Expected offset #{offset} but got #{last_call[:offset]}")
  assert_equal(limit,  last_call[:limit],    "Expected limit #{limit} but got #{last_call[:limit]}")
end
