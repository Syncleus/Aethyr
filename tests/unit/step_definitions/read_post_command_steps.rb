# frozen_string_literal: true
###############################################################################
# Step definitions for ReadPostCommand action coverage.                        #
#                                                                              #
# These steps exercise every branch of                                         #
# lib/aethyr/core/actions/commands/read_post.rb to achieve >97% line           #
# coverage.                                                                    #
#                                                                              #
# All collaborators ($manager, find_board, player callbacks) are stubbed to    #
# isolate the command logic under test.                                        #
###############################################################################

require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/read_post'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module ReadPostWorld
  attr_accessor :rpost_player, :rpost_command, :rpost_board,
                :rpost_room, :rpost_find_board_result,
                :rpost_post, :rpost_post_id
end
World(ReadPostWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal info double that behaves like an OpenStruct for the boards attribute.
class RpostMockInfo
  attr_accessor :boards
  def initialize(boards = nil)
    @boards = boards
  end
end

# Minimal player double that records output.
class RpostMockPlayer
  attr_accessor :container, :name, :word_wrap
  attr_reader   :messages, :info

  def initialize(name, container)
    @name      = name
    @container = container
    @messages  = []
    @word_wrap = nil
    @info      = RpostMockInfo.new(nil)
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Minimal board double that supports get_post, show_post, and goid.
class RpostMockBoard
  attr_reader :goid

  def initialize(goid: :rpost_board_goid)
    @goid  = goid
    @posts = {}
  end

  def add_post(post_id, post)
    @posts[post_id] = post
  end

  def get_post(post_id)
    @posts[post_id]
  end

  def show_post(post, _wrap)
    post[:content]
  end
end

# Minimal room double.
class RpostMockRoom; end

###############################################################################
# Manager stub                                                                 #
###############################################################################
class RpostMockManager
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
  @rpost_saved_manager = $manager
end

After do
  $manager = @rpost_saved_manager if defined?(@rpost_saved_manager)
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed ReadPostCommand environment') do
  self.rpost_room    = RpostMockRoom.new
  self.rpost_player  = RpostMockPlayer.new('TestReader', :rpost_room_id)
  self.rpost_post_id = 3

  # Wire up $manager
  manager = RpostMockManager.new
  manager.register(:rpost_room_id, rpost_room)
  $manager = manager

  # Defaults
  self.rpost_find_board_result = nil
  self.rpost_board             = nil
  self.rpost_post              = nil
end

Given('the rpost board lookup will return nil') do
  self.rpost_find_board_result = nil
  self.rpost_board             = nil
end

Given('the rpost board lookup will return a board') do
  self.rpost_board = RpostMockBoard.new(goid: :rpost_board_goid)
  self.rpost_find_board_result = rpost_board
end

Given('the rpost board will return nil for the requested post') do
  # Board exists but has no post for the given post_id – get_post returns nil
end

Given('the rpost board will return a post for the requested post') do
  self.rpost_post = { content: "This is the post body text." }
  rpost_board.add_post(rpost_post_id, rpost_post)
end

Given('the rpost player info boards is nil') do
  rpost_player.info.boards = nil
end

Given('the rpost player info boards already exists') do
  rpost_player.info.boards = { some_other_board: 1 }
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the rpost read post command is invoked') do
  self.rpost_command = Aethyr::Core::Actions::ReadPost::ReadPostCommand.new(
    rpost_player,
    player:  rpost_player,
    post_id: rpost_post_id
  )

  # Stub find_board on the command instance (mixed in at runtime normally)
  board_result = rpost_find_board_result
  rpost_command.define_singleton_method(:find_board) do |_event, _room|
    board_result
  end

  rpost_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the rpost player should see {string}') do |expected|
  assert(
    rpost_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{rpost_player.messages.inspect}"
  )
end

Then('the rpost player info boards should be initialized') do
  assert_not_nil(
    rpost_player.info.boards,
    "Expected player.info.boards to be initialized but it is nil"
  )
  assert_kind_of(Hash, rpost_player.info.boards,
    "Expected player.info.boards to be a Hash")
end

Then('the rpost player info boards should track the post id for the board') do
  boards = rpost_player.info.boards
  assert_not_nil(boards, "Expected player.info.boards to exist")
  assert_equal(
    rpost_post_id.to_i,
    boards[rpost_board.goid],
    "Expected boards[#{rpost_board.goid.inspect}] to be #{rpost_post_id.to_i} " \
    "but got #{boards[rpost_board.goid].inspect}"
  )
end

Then('the rpost player should see the post content') do
  assert(
    rpost_player.messages.any? { |m| m.include?("This is the post body text.") },
    "Expected player output to contain post content but got: #{rpost_player.messages.inspect}"
  )
end
