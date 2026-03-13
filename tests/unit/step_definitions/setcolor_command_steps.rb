# frozen_string_literal: true
###############################################################################
# Step definitions for SetcolorCommand action coverage.                       #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/setcolor'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module SetcolorWorld
  attr_accessor :scolor_player, :scolor_option, :scolor_color
end
World(SetcolorWorld)

###############################################################################
# Lightweight IO double that records use_color writes, to_default calls,      #
# and set_color invocations.                                                  #
###############################################################################
class ScolorMockIo
  attr_accessor :use_color
  attr_reader :to_default_count, :set_color_calls

  def initialize
    @use_color        = true
    @to_default_count = 0
    @set_color_calls  = []
  end

  def to_default
    @to_default_count += 1
  end

  def set_color(option, color)
    @set_color_calls << { option: option, color: color }
    "Color for #{option} set to #{color}."
  end
end

###############################################################################
# Lightweight player double                                                   #
###############################################################################
class ScolorMockPlayer
  attr_accessor :container, :name
  attr_reader :messages, :io

  def initialize
    @container = "scolor_room_1"
    @name      = "ScolorTestPlayer"
    @messages  = []
    @io        = ScolorMockIo.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed SetcolorCommand environment') do
  @scolor_player = ScolorMockPlayer.new
  @scolor_option = nil
  @scolor_color  = nil

  room_obj = OpenStruct.new(name: "Test Room", goid: "scolor_room_1")

  mgr = Object.new
  player_ref = @scolor_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  $manager = mgr
end

Given('the scolor option is {string}') do |opt|
  @scolor_option = opt
end

Given('the scolor color is {string}') do |col|
  @scolor_color = col
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the SetcolorCommand action is invoked') do
  data = { option: @scolor_option }
  data[:color] = @scolor_color unless @scolor_color.nil?

  cmd = Aethyr::Core::Actions::Setcolor::SetcolorCommand.new(
    @scolor_player, **data
  )
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the scolor player should see {string}') do |fragment|
  match = @scolor_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@scolor_player.messages.inspect}")
end

Then('the scolor player io use_color should be false') do
  assert_equal(false, @scolor_player.io.use_color,
    "Expected use_color to be false, got #{@scolor_player.io.use_color.inspect}")
end

Then('the scolor player io use_color should be true') do
  assert_equal(true, @scolor_player.io.use_color,
    "Expected use_color to be true, got #{@scolor_player.io.use_color.inspect}")
end

Then('the scolor player io to_default should have been called') do
  assert(@scolor_player.io.to_default_count > 0,
    "Expected player.io.to_default to have been called, but it was not.")
end

Then('the scolor player io set_color should have been called with {string} and {string}') do |opt, col|
  call = @scolor_player.io.set_color_calls.find { |c| c[:option] == opt && c[:color] == col }
  assert(call,
    "Expected player.io.set_color(#{opt.inspect}, #{col.inspect}) to have been called, " \
    "got: #{@scolor_player.io.set_color_calls.inspect}")
end
