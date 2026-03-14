# frozen_string_literal: true
###############################################################################
# Step definitions for ShowcolorsCommand action coverage.                     #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/showcolors'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module ShowcolorsWorld
  attr_accessor :showcolors_player
end
World(ShowcolorsWorld)

###############################################################################
# Lightweight display double that returns a known color config string.        #
###############################################################################
class ShowcolorsTestDisplay
  def show_color_config
    "color_config_output"
  end
end

###############################################################################
# Lightweight IO double that exposes a display with show_color_config.        #
###############################################################################
class ShowcolorsTestIo
  attr_reader :display

  def initialize
    @display = ShowcolorsTestDisplay.new
  end
end

###############################################################################
# Lightweight player double                                                   #
###############################################################################
class ShowcolorsTestPlayer
  attr_accessor :container, :name
  attr_reader :messages, :io

  def initialize
    @container = "showcolors_room_1"
    @name      = "ShowcolorsTestPlayer"
    @messages  = []
    @io        = ShowcolorsTestIo.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed ShowcolorsCommand environment') do
  @showcolors_player = ShowcolorsTestPlayer.new

  room_obj = OpenStruct.new(name: "Test Room", goid: "showcolors_room_1")

  mgr = Object.new
  player_ref = @showcolors_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  $manager = mgr
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the ShowcolorsCommand action is invoked') do
  cmd = Aethyr::Core::Actions::Showcolors::ShowcolorsCommand.new(
    @showcolors_player
  )
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the showcolors player should see the color config') do
  match = @showcolors_player.messages.any? { |m| m.include?("color_config_output") }
  assert(match,
    "Expected player output containing 'color_config_output', got: #{@showcolors_player.messages.inspect}")
end
