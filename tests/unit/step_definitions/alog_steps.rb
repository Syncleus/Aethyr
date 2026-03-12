# frozen_string_literal: true
###############################################################################
# Step definitions for AlogCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/alog'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AlogWorld
  attr_accessor :alog_player, :alog_command, :alog_value,
                :alog_log_dumped, :alog_tail_calls
end
World(AlogWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AlogPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "alog_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "alog_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Minimal LOG double that records dump calls.
class AlogLogDouble
  attr_reader :dump_count

  def initialize
    @dump_count = 0
  end

  def dump
    @dump_count += 1
  end

  # The Object#log method introspects $LOG.method(:add).parameters,
  # so we must provide an `add` method with a compatible signature.
  def add(severity, msg = nil, progname = nil, dump_log: false)
    # no-op for testing
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AlogCommand environment') do
  @alog_player     = AlogPlayer.new
  @alog_command    = nil
  @alog_value      = nil
  @alog_log_dumped = false
  @alog_tail_calls = []

  # Ensure `log` is available as a no-op (called in the "flush" branch).
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: "alog_room_goid_1")

  # Build a stub manager
  mgr = Object.new
  player_ref = @alog_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  $manager = mgr

  # Set up a LOG double to track dump calls
  @alog_log_double = AlogLogDouble.new
  $LOG = @alog_log_double

  # Stub ServerConfig if not yet defined
  unless defined?(::ServerConfig)
    module ::ServerConfig
      @data = {}
      class << self
        def [](key);       @data[key]; end
        def []=(key, val); @data[key] = val; end
      end
    end
  end
end

Given('the alog command is not set') do
  @alog_command = nil
end

Given('the alog command is {string}') do |cmd|
  @alog_command = cmd
end

Given('the alog value is {string}') do |val|
  @alog_value = val
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AlogCommand action is invoked') do
  data = {}
  data[:command] = @alog_command if @alog_command
  data[:value]   = @alog_value   if @alog_value

  cmd = Aethyr::Core::Actions::Alog::AlogCommand.new(@alog_player, **data)

  # Patch `tail` on this instance so it returns a predictable string
  # without needing actual log files on disk.
  tail_calls = @alog_tail_calls
  cmd.define_singleton_method(:tail) do |file, lines = 10|
    tail_calls << { file: file, lines: lines }
    "tail output from #{file} (#{lines} lines)"
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the alog player should see {string}') do |fragment|
  match = @alog_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected alog player output containing #{fragment.inspect}, got: #{@alog_player.messages.inspect}")
end

Then('the global LOG should have been dumped') do
  assert(@alog_log_double.dump_count > 0,
    "Expected $LOG.dump to have been called at least once, but it was not.")
end

Then('the alog server config log_level should be {int}') do |level|
  assert_equal(level, ServerConfig[:log_level],
    "Expected ServerConfig[:log_level] to be #{level}, got #{ServerConfig[:log_level]}")
end
