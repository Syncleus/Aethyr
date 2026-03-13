# frozen_string_literal: true
###############################################################################
# Step definitions for DeletePostCommand action coverage.                      #
#                                                                              #
# These steps exercise every branch of                                         #
# lib/aethyr/core/actions/commands/delete_post.rb to achieve >97% line         #
# coverage.                                                                    #
#                                                                              #
# All collaborators ($manager, find_board, player callbacks) are stubbed to    #
# isolate the command logic under test.                                        #
###############################################################################

require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/delete_post'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module DeletePostWorld
  attr_accessor :dpost_player, :dpost_command, :dpost_board,
                :dpost_room, :dpost_find_board_result,
                :dpost_post_id
end
World(DeletePostWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal player double that records output.
class DpostMockPlayer
  attr_accessor :container, :name

  def initialize(name, container)
    @name      = name
    @container = container
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def messages
    @messages
  end
end

# Minimal board double that supports get_post and delete_post.
class DpostMockBoard
  attr_reader :deleted_post_ids

  def initialize
    @posts            = {}
    @deleted_post_ids = []
  end

  def add_post(post_id, post)
    @posts[post_id] = post
  end

  def get_post(post_id)
    @posts[post_id]
  end

  def delete_post(post_id)
    @deleted_post_ids << post_id
    @posts.delete(post_id)
  end
end

# Minimal room double.
class DpostMockRoom; end

###############################################################################
# Manager stub                                                                 #
###############################################################################
class DpostMockManager
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
  @dpost_saved_manager = $manager
end

After do
  $manager = @dpost_saved_manager if defined?(@dpost_saved_manager)
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed DeletePostCommand environment') do
  self.dpost_room    = DpostMockRoom.new
  self.dpost_player  = DpostMockPlayer.new('TestDeleter', :dpost_room_id)
  self.dpost_post_id = 7

  # Wire up $manager
  manager = DpostMockManager.new
  manager.register(:dpost_room_id, dpost_room)
  $manager = manager

  # Defaults
  self.dpost_find_board_result = nil
  self.dpost_board             = nil
end

Given('the dpost board lookup will return nil') do
  self.dpost_find_board_result = nil
  self.dpost_board             = nil
end

Given('the dpost board lookup will return a board') do
  self.dpost_board = DpostMockBoard.new
  self.dpost_find_board_result = dpost_board
end

Given('the dpost board has no post for the requested id') do
  # Board exists but has no post for the given post_id – get_post returns nil
end

Given('the dpost board has a post by {string}') do |author_name|
  dpost_board.add_post(dpost_post_id, { author: author_name })
end

Given('the dpost board has a post by the current player') do
  dpost_board.add_post(dpost_post_id, { author: dpost_player.name })
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the dpost delete post command is invoked') do
  self.dpost_command = Aethyr::Core::Actions::DeletePost::DeletePostCommand.new(
    dpost_player,
    player:  dpost_player,
    post_id: dpost_post_id
  )

  # Stub find_board on the command instance (mixed in at runtime normally)
  board_result = dpost_find_board_result
  dpost_command.define_singleton_method(:find_board) do |_event, _room|
    board_result
  end

  dpost_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the dpost player should see {string}') do |expected|
  assert(
    dpost_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{dpost_player.messages.inspect}"
  )
end

Then('the dpost board should have deleted post {int}') do |post_id|
  assert(
    dpost_board.deleted_post_ids.include?(post_id),
    "Expected board to have deleted post ##{post_id} but deleted: #{dpost_board.deleted_post_ids.inspect}"
  )
end
