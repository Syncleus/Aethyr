# frozen_string_literal: true
###############################################################################
# Step definitions for AsaveCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/asave'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AsaveWorld
  attr_accessor :asave_player, :asave_save_all_calls
end
World(AsaveWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AsavePlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "asave_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "asave_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AsaveCommand environment') do
  @asave_player         = AsavePlayer.new
  @asave_save_all_calls = []

  # Ensure `log` is available as a no-op.
  # The production code calls `log` which is a private method on Object
  # defined by aethyr/core/util/log.rb.
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: @asave_player.container)

  # Build a stub manager with get_object and save_all
  player_ref      = @asave_player
  save_all_calls  = @asave_save_all_calls

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  mgr.define_singleton_method(:save_all) do
    save_all_calls << true
  end

  mgr.define_singleton_method(:submit_action) { |_a| }

  $manager = mgr
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AsaveCommand action is invoked') do
  cmd = Aethyr::Core::Actions::Asave::AsaveCommand.new(@asave_player)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the asave player should see {string}') do |fragment|
  match = @asave_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected asave player output containing #{fragment.inspect}, got: #{@asave_player.messages.inspect}")
end

Then('the asave manager save_all should have been called') do
  assert(!@asave_save_all_calls.empty?,
    "Expected $manager.save_all to have been called at least once, but it was not.")
end
