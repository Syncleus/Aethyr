# frozen_string_literal: true
###############################################################################
# Step definitions for WritePostCommand action coverage.                       #
#                                                                              #
# These steps exercise every branch of                                         #
# lib/aethyr/core/actions/commands/write_post.rb to achieve >97% line          #
# coverage.                                                                    #
#                                                                              #
# All collaborators ($manager, find_board, player callbacks) are stubbed to    #
# isolate the command logic under test.                                        #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/write_post'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module WritePostWorld
  attr_accessor :wpost_player, :wpost_command, :wpost_board,
                :wpost_room, :wpost_area, :wpost_board_container,
                :wpost_find_board_result, :wpost_reply_to
end
World(WritePostWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal player double that records output and immediately invokes
# expect/editor callbacks with pre-configured values.
class WpostMockPlayer
  attr_accessor :container, :name
  attr_reader   :messages

  def initialize(name, container)
    @name           = name
    @container      = container
    @messages       = []
    @queued_subject = nil
    @queued_message = nil  # nil means "editor cancelled"
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  # Queue a subject string to feed into the expect callback.
  def queue_subject(subj)
    @queued_subject = subj
  end

  # Queue a message string (or nil to simulate editor cancellation).
  def queue_message(msg)
    @queued_message = msg
  end

  # Immediately invoke the callback with the queued subject.
  def expect(&block)
    block.call(@queued_subject) if block
  end

  # Immediately invoke the callback with the queued message (or nil).
  def editor(&block)
    block.call(@queued_message) if block
  end
end

# Minimal board double that records save_post calls.
class WpostMockBoard
  attr_accessor :announce_new, :container
  attr_reader   :saved_posts

  def initialize(announce_new: nil, container: :wpost_board_container_id)
    @announce_new = announce_new
    @container    = container
    @saved_posts  = []
    @next_post_id = 1
  end

  def save_post(player, subject, reply_to, message)
    post_id = @next_post_id
    @next_post_id += 1
    @saved_posts << {
      player:   player,
      subject:  subject,
      reply_to: reply_to,
      message:  message,
      post_id:  post_id
    }
    post_id
  end
end

# Minimal area double that records output calls.
class WpostMockArea
  attr_reader :messages

  def initialize
    @messages = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Minimal board-container double returned by $manager.get_object(board.container).
class WpostMockBoardContainer
  attr_accessor :area

  def initialize(area)
    @area = area
  end
end

# Minimal room double (returned by $manager.get_object(player.container)).
class WpostMockRoom; end

###############################################################################
# Manager stub – dispatches get_object based on the requested GOID             #
###############################################################################
class WpostMockManager
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
  @wpost_saved_manager = $manager
end

After do
  $manager = @wpost_saved_manager if defined?(@wpost_saved_manager)
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed WritePostCommand environment') do
  # Build collaborators
  self.wpost_area             = WpostMockArea.new
  self.wpost_board_container  = WpostMockBoardContainer.new(wpost_area)
  self.wpost_room             = WpostMockRoom.new
  self.wpost_reply_to         = nil

  # Player lives in room identified by a symbolic GOID
  self.wpost_player = WpostMockPlayer.new('TestWriter', :wpost_room_id)

  # Wire up $manager
  manager = WpostMockManager.new
  manager.register(:wpost_room_id, wpost_room)
  manager.register(:wpost_board_container_id, wpost_board_container)
  $manager = manager

  # Default: no board (will be overridden per-scenario)
  self.wpost_find_board_result = nil
  self.wpost_board             = nil
end

Given('the wpost board lookup will return nil') do
  self.wpost_find_board_result = nil
  self.wpost_board             = nil
end

Given('the wpost board lookup will return a board without announcement') do
  self.wpost_board = WpostMockBoard.new(announce_new: nil)
  self.wpost_find_board_result = wpost_board
end

Given('the wpost board lookup will return a board with announcement {string}') do |announcement|
  self.wpost_board = WpostMockBoard.new(
    announce_new: announcement,
    container:    :wpost_board_container_id
  )
  self.wpost_find_board_result = wpost_board
end

Given('the wpost player will enter subject {string} and message {string}') do |subject, message|
  wpost_player.queue_subject(subject)
  wpost_player.queue_message(message)
end

Given('the wpost player will enter subject {string} and cancel the editor') do |subject|
  wpost_player.queue_subject(subject)
  wpost_player.queue_message(nil)
end

Given('the wpost command will have reply_to set to {int}') do |reply_id|
  self.wpost_reply_to = reply_id
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the wpost write post command is invoked') do
  self.wpost_command = Aethyr::Core::Actions::WritePost::WritePostCommand.new(
    wpost_player,
    player:   wpost_player,
    reply_to: wpost_reply_to
  )

  # Stub find_board on the command instance so it returns our mock
  board_result = wpost_find_board_result
  wpost_command.define_singleton_method(:find_board) do |_event, _room|
    board_result
  end

  wpost_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the wpost player should see {string}') do |expected|
  assert(
    wpost_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{wpost_player.messages.inspect}"
  )
end

Then('the wpost board should not have received a save') do
  if wpost_board
    assert_equal(
      0, wpost_board.saved_posts.size,
      "Expected no saves but got: #{wpost_board.saved_posts.inspect}"
    )
  end
  # If wpost_board is nil (no board scenario), there is nothing to check.
end

Then('the wpost board should have saved a post from the player with subject {string} and message {string}') do |subject, message|
  assert_not_nil(wpost_board, 'Expected a board to exist')
  assert_equal(1, wpost_board.saved_posts.size,
               "Expected exactly 1 save but got #{wpost_board.saved_posts.size}")

  saved = wpost_board.saved_posts.first
  assert_equal(subject, saved[:subject],
               "Expected subject '#{subject}' but got '#{saved[:subject]}'")
  assert_equal(message, saved[:message],
               "Expected message '#{message}' but got '#{saved[:message]}'")
  assert_equal(wpost_player, saved[:player],
               'Expected the saved player to be the test player')
end

Then('the wpost board should have saved a post with reply_to {int}') do |reply_id|
  assert_not_nil(wpost_board, 'Expected a board to exist')
  assert(wpost_board.saved_posts.size >= 1, 'Expected at least one saved post')

  saved = wpost_board.saved_posts.first
  assert_equal(reply_id, saved[:reply_to],
               "Expected reply_to #{reply_id} but got #{saved[:reply_to].inspect}")
end

Then('the wpost area should not have received output') do
  assert_equal(
    0, wpost_area.messages.size,
    "Expected no area output but got: #{wpost_area.messages.inspect}"
  )
end

Then('the wpost area should have received output {string}') do |expected|
  assert(
    wpost_area.messages.any? { |m| m.include?(expected) },
    "Expected area output to contain '#{expected}' but got: #{wpost_area.messages.inspect}"
  )
end
