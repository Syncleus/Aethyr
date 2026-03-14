# frozen_string_literal: true
###############################################################################
# Step definitions for AreloadCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'tempfile'
require 'aethyr/core/actions/commands/areload'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AreloadWorld
  attr_accessor :areload_player, :areload_room, :areload_command, :areload_tempfile
end
World(AreloadWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

class AreloadTestPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize
    @container = 'areload_room_1'
    @name      = 'AreloadTestPlayer'
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

class AreloadTestRoom
  attr_accessor :name

  def initialize
    @name = 'Test Room'
  end
end

class AreloadTestManager
  attr_accessor :room

  def initialize(room)
    @room = room
  end

  def get_object(_id)
    @room
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AreloadCommand environment') do
  @areload_player = AreloadTestPlayer.new
  @areload_room   = AreloadTestRoom.new

  $manager = AreloadTestManager.new(@areload_room)
end

Given('a temporary Ruby file to reload') do
  @areload_tempfile = Tempfile.new(['areload_test', '.rb'])
  @areload_tempfile.write("# areload test file\n")
  @areload_tempfile.flush
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AreloadCommand action is invoked with the temp file') do
  # Strip the .rb extension since the command appends it
  object_path = @areload_tempfile.path.sub(/\.rb\z/, '')

  @areload_command = Aethyr::Core::Actions::Areload::AreloadCommand.new(
    @areload_player, object: object_path
  )
  @areload_command.action
end

When('the AreloadCommand action is invoked with a nonexistent file') do
  @areload_command = Aethyr::Core::Actions::Areload::AreloadCommand.new(
    @areload_player, object: '/tmp/nonexistent_areload_file_xyz_999'
  )
  @areload_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the areload player should see {string}') do |fragment|
  match = @areload_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@areload_player.messages.inspect}")
end
