# frozen_string_literal: true
###############################################################################
# Step definitions for SetCommand action coverage.                            #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/set'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module SetWorld
  attr_accessor :set_player, :set_setting, :set_value, :set_editor_yields_nil
end
World(SetWorld)

###############################################################################
# Recording player double that captures output messages and supports          #
# all attributes used by SetCommand.                                          #
###############################################################################
class SetTestPlayer
  attr_accessor :container, :name, :goid, :word_wrap, :page_height,
                :layout, :long_desc
  attr_reader :messages

  def initialize
    @container  = "room_goid_1"
    @name       = "TestPlayer"
    @goid       = "set_player_goid_1"
    @messages   = []
    @word_wrap  = nil
    @page_height = nil
    @layout     = nil
    @long_desc  = "original description"
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  # editor(text, lines) { |data| ... }
  # We simulate the editor by immediately yielding data back.
  # By default we yield a non-nil string; tests can override via
  # @set_editor_yields_nil to test the nil-data branch.
  def editor(text, _lines, &block)
    if @_editor_yields_nil
      block.call(nil)
    else
      block.call("  new description  ")
    end
  end

  def editor_yields_nil!
    @_editor_yields_nil = true
  end

  # Needed for line 73: player.instance_variable_get(:@long_desc)
  # The attr_accessor already stores in @long_desc, so this just works.
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed SetCommand environment') do
  @set_player = SetTestPlayer.new
  @set_setting = nil
  @set_value = :__unset__  # sentinel to distinguish "not provided" from nil
  @set_editor_yields_nil = false

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: "room_goid_1")

  mgr = Object.new
  player_ref = @set_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  $manager = mgr
end

Given('the set player has word_wrap set to nil') do
  @set_player.word_wrap = nil
end

Given('the set player has word_wrap set to {int}') do |val|
  @set_player.word_wrap = val
end

Given('the set player has page_height set to nil') do
  @set_player.page_height = nil
end

Given('the set player has page_height set to {int}') do |val|
  @set_player.page_height = val
end

Given('the set setting is {string}') do |setting|
  @set_setting = setting
end

Given('the set value is nil') do
  @set_value = nil
end

Given('the set value is {string}') do |val|
  @set_value = val
end

Given('the editor will yield nil data') do
  @set_editor_yields_nil = true
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the SetCommand action is invoked') do
  data = { setting: @set_setting }
  if @set_value != :__unset__
    data[:value] = @set_value
  end

  cmd = Aethyr::Core::Actions::Set::SetCommand.new(@set_player, **data)

  # If editor should yield nil, mark the player
  if @set_editor_yields_nil
    @set_player.editor_yields_nil!
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the set player should see {string}') do |fragment|
  match = @set_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@set_player.messages.inspect}")
end

Then('the set player layout should be {word}') do |expected_sym|
  # expected_sym comes in as ":basic" etc.
  expected = expected_sym.delete_prefix(':').to_sym
  assert_equal(expected, @set_player.layout,
    "Expected layout #{expected.inspect}, got #{@set_player.layout.inspect}")
end

Then('the set player long_desc should be {string}') do |expected|
  assert_equal(expected, @set_player.long_desc,
    "Expected long_desc #{expected.inspect}, got #{@set_player.long_desc.inspect}")
end
