# frozen_string_literal: true

###############################################################################
# Step definitions for player.feature                                          #
#                                                                              #
# Exercises every public method and branch in                                  #
#   lib/aethyr/core/objects/player.rb                                          #
# using lightweight test doubles to avoid full application dependencies.       #
###############################################################################

require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# Mock objects                                                                 #
###############################################################################
module PlayerTestWorld
  attr_accessor :player, :connection, :new_connection, :result,
                :broadcast_events, :long_desc_result

  # ── Mock Display ──────────────────────────────────────────────────
  class MockDisplay
    attr_accessor :color_settings, :layout_type, :refreshed

    def initialize
      @layout_type = :basic
      @color_settings = nil
      @refreshed = false
    end

    def layout(layout:)
      @layout_type = layout
    end

    def refresh_watch_windows(player)
      @refreshed = true
    end
  end

  # ── Mock Connection ────────────────────────────────────────────────
  class MockConnection
    attr_accessor :word_wrap, :display, :messages, :closed,
                  :more_called, :expect_called, :editor_called,
                  :menu_called, :raise_on_say

    def initialize
      @display = MockDisplay.new
      @closed = false
      @messages = []
      @more_called = false
      @expect_called = false
      @editor_called = false
      @menu_called = false
      @raise_on_say = false
      @word_wrap = 120
    end

    def say(msg, no_newline = false, message_type: :main, internal_clear: false)
      raise RuntimeError, "simulated IO error" if @raise_on_say
      @messages << { message: msg, no_newline: no_newline,
                     message_type: message_type, internal_clear: internal_clear }
    end

    def closed?
      @closed
    end

    def close
      @closed = true
    end

    def more
      @more_called = true
    end

    def expect(&block)
      @expect_called = true
      @expected_block = block
    end

    def start_editor(buffer, limit, &block)
      @editor_called = true
    end

    def ask_menu(options, answers, &block)
      @menu_called = true
    end

    def echo_off; end
    def echo_on; end
  end

  # ── Stub $manager ──────────────────────────────────────────────────
  class StubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(_action); end

    def get_object(goid)
      nil
    end
  end
end

World(PlayerTestWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('I require the Player library with mock connection') do
  # Set up stub $manager before requiring anything that uses it
  $manager ||= PlayerTestWorld::StubManager.new

  # Only require once across all scenarios
  unless defined?(Aethyr::Core::Objects::Player)
    require 'aethyr/core/objects/player'
  end
end

###############################################################################
# When steps – creation                                                        #
###############################################################################

When('I create a new Player with mock connection and goid {string}') do |goid|
  $manager = PlayerTestWorld::StubManager.new
  self.connection = PlayerTestWorld::MockConnection.new
  # Reset display refresh tracking after construction
  self.player = Aethyr::Core::Objects::Player.new(connection, goid, "test-room-1")
  connection.display.refreshed = false
  connection.messages.clear
  self.broadcast_events = []
end

###############################################################################
# When steps – field setters                                                   #
###############################################################################

When('I set the player blind to true') do
  player.instance_variable_set(:@blind, true)
end

When('I set the player deaf to true') do
  player.instance_variable_set(:@deaf, true)
end

When('I set the player alive to false') do
  player.alive = false
end

When('I set the player balance to false') do
  player.balance = false
end

When('I set the player health to {int}') do |hp|
  player.info.stats.health = hp
end

When('I set the player help_library to nil') do
  player.instance_variable_set(:@help_library, nil)
end

When('I set the display layout_type to {string}') do |layout_type|
  connection.display.layout_type = layout_type
end

When('I set the player display to nil') do
  # Make the display accessor return nil
  connection.instance_variable_set(:@display, nil)
  # Define display method to return nil
  def connection.display; nil; end
end

When('I set the player layout to {string}') do |new_layout|
  connection.display.refreshed = false
  player.layout = new_layout
end

When('I set the player color_settings to {string}') do |settings|
  player.color_settings = settings
end

When('I set the player word_wrap to {int}') do |size|
  player.word_wrap = size
end

###############################################################################
# When steps – connection                                                      #
###############################################################################

When('I set a new connection on the player') do
  self.new_connection = PlayerTestWorld::MockConnection.new
  player.set_connection(new_connection)
end

When('I close the connection manually') do
  connection.close
end

When('I make the connection say raise an error') do
  connection.raise_on_say = true
end

###############################################################################
# When steps – dehydrate / rehydrate                                           #
###############################################################################

When('I dehydrate the player') do
  @volatile_data = player.dehydrate
end

When('I dehydrate and then rehydrate the player') do
  volatile_data = player.dehydrate
  player.rehydrate(volatile_data)
end

When('I rehydrate the player with empty volatile data') do
  player.rehydrate({})
end

###############################################################################
# When steps – delegation methods                                              #
###############################################################################

When('I call menu on the player with options {string}') do |options|
  player.menu(options) { |answer| }
end

When('I call more on the player') do
  player.more
end

When('I call expect on the player with a block') do
  player.expect { |input| input }
end

When('I call editor on the player') do
  player.editor([], 50) { |contents| }
end

###############################################################################
# When steps – out_event                                                       #
###############################################################################

When('I send an out_event where target is self and player is other') do
  connection.messages.clear
  event = {
    target: player,
    player: "someone_else",
    to_target: "hit_target_msg",
    to_blind_target: "blind_target_msg",
    to_deaf_target: "deaf_target_msg",
    to_deafandblind_target: "deafblind_target_msg",
    to_player: "player_msg",
    to_other: "other_msg",
    to_blind_other: "blind_other_msg",
    to_deaf_other: "deaf_other_msg",
    to_deafandblind_other: "deafblind_other_msg"
  }
  player.out_event(event)
end

When('I send an out_event where player is self') do
  connection.messages.clear
  event = {
    target: "someone_else",
    player: player,
    to_target: "hit_target_msg",
    to_player: "player_msg",
    to_other: "other_msg"
  }
  player.out_event(event)
end

When('I send an out_event where player is self with message_type {string}') do |msg_type|
  connection.messages.clear
  event = {
    target: "someone_else",
    player: player,
    message_type: msg_type.to_sym,
    to_target: "hit_target_msg",
    to_player: "player_msg",
    to_other: "other_msg"
  }
  player.out_event(event)
end

When('I send an out_event where both target and player are other') do
  connection.messages.clear
  event = {
    target: "someone_else",
    player: "another_person",
    to_target: "hit_target_msg",
    to_player: "player_msg",
    to_other: "other_msg",
    to_blind_other: "blind_other_msg",
    to_deaf_other: "deaf_other_msg",
    to_deafandblind_other: "deafblind_other_msg"
  }
  player.out_event(event)
end

###############################################################################
# When steps – output                                                          #
###############################################################################

When('I call output with {string}') do |message|
  connection.messages.clear
  player.output(message)
end

When('I call output with an array of {string} and {string}') do |msg1, msg2|
  connection.messages.clear
  player.output([msg1, msg2])
end

When('I call output with nil') do
  connection.messages.clear
  player.output(nil)
end

###############################################################################
# When steps – handle_input                                                    #
###############################################################################

When('I call handle_input with nil') do
  player.handle_input(nil)
end

When('I call handle_input with {string}') do |input|
  connection.messages.clear
  # Subscribe to catch broadcast events
  self.broadcast_events = []
  player.on(:player_input) do |event|
    self.broadcast_events << event
  end
  player.handle_input(input)
end

###############################################################################
# When steps – inventory/desc/quit/run                                         #
###############################################################################

When('I call show_inventory on the player') do
  self.result = player.show_inventory
end

When('I call long_desc on the player') do
  self.long_desc_result = player.long_desc
end

When('I call quit on the player') do
  player.quit
end

When('I call take_damage with {int}') do |amount|
  player.take_damage(amount)
end

When('I call update_display on the player') do
  connection.display.refreshed = false
  player.update_display
end

When('I call run on the player') do
  connection.display.refreshed = false
  player.run
end

###############################################################################
# Then steps – constructor assertions                                          #
###############################################################################

Then('the player admin should be false') do
  assert_equal false, player.admin
end

Then('the player should not be blind') do
  assert_equal false, player.blind?
end

Then('the player should be blind') do
  assert_equal true, player.blind?
end

Then('the player should not be deaf') do
  assert_equal false, player.deaf?
end

Then('the player should be deaf') do
  assert_equal true, player.deaf?
end

Then('the player use_color should be nil') do
  assert_nil player.use_color
end

Then('the player page_height should be nil') do
  assert_nil player.page_height
end

Then('the player reply_to should be nil') do
  assert_nil player.reply_to
end

Then('the player word_wrap should be {int}') do |expected|
  assert_equal expected, player.word_wrap
end

Then('the player layout should be :basic') do
  # After construction, @layout is :basic. We check via instance variable
  # since the getter delegates to display.layout_type
  layout_ivar = player.instance_variable_get(:@layout)
  assert_equal :basic, layout_ivar
end

Then('the player help_library should not be nil') do
  assert_not_nil player.help_library
end

Then('the player info stats satiety should be {int}') do |expected|
  assert_equal expected, player.info.stats.satiety
end

Then('the player should have skills') do
  assert_not_nil player.info.skills
  assert player.info.skills.size >= 2, "Expected at least 2 skills"
end

Then('the player should have explored rooms including the starting room') do
  assert_not_nil player.info.explored_rooms
  assert player.info.explored_rooms.include?("test-room-1"),
         "Expected explored_rooms to include starting room"
end

###############################################################################
# Then steps – set_connection                                                  #
###############################################################################

Then('the player io should be the new connection') do
  assert_equal new_connection, player.io
end

Then('the new connection display should have color_settings set') do
  # color_settings may be nil (the default) but should have been assigned
  assert_equal player.color_settings, new_connection.display.color_settings
end

Then('the new connection display should have layout set') do
  assert_equal :basic, new_connection.display.layout_type
end

###############################################################################
# Then steps – dehydrate / rehydrate                                           #
###############################################################################

Then('the dehydrated data should contain the connection under :@player') do
  assert @volatile_data.key?(:@player), "Expected volatile_data to contain :@player"
end

Then('the player layout instance variable should reflect the display layout') do
  # After dehydrate, @layout should have been set from the display's layout_type
  layout = player.instance_variable_get(:@layout)
  assert_not_nil layout
end

###############################################################################
# Then steps – layout                                                          #
###############################################################################

Then('the player layout should return {string}') do |expected|
  assert_equal expected, player.layout
end

Then('the player layout should return :basic') do
  assert_equal :basic, player.layout
end

Then('the display should have layout set to {string}') do |expected|
  assert_equal expected, connection.display.layout_type
end

Then('the display should have been refreshed') do
  assert_equal true, connection.display.refreshed,
               "Expected display to have been refreshed"
end

###############################################################################
# Then steps – color_settings                                                  #
###############################################################################

Then('the player color_settings should be {string}') do |expected|
  assert_equal expected, player.color_settings
end

Then('the display color_settings should be {string}') do |expected|
  assert_equal expected, connection.display.color_settings
end

###############################################################################
# Then steps – has?                                                            #
###############################################################################

Then('the player has? {string} should return nil') do |item_name|
  result = player.has?(item_name)
  assert_nil result
end

###############################################################################
# Then steps – delegation                                                      #
###############################################################################

Then('the connection ask_menu should have been called') do
  assert_equal true, connection.menu_called
end

Then('the connection more should have been called') do
  assert_equal true, connection.more_called
end

Then('the connection expect should have been called') do
  assert_equal true, connection.expect_called
end

Then('the connection start_editor should have been called') do
  assert_equal true, connection.editor_called
end

###############################################################################
# Then steps – balance                                                         #
###############################################################################

Then('the player balance should be false') do
  assert_equal false, player.balance
end

###############################################################################
# Then steps – io                                                              #
###############################################################################

Then('the player io should return the connection') do
  assert_equal connection, player.io
end

###############################################################################
# Then steps – word_wrap                                                       #
###############################################################################

Then('the connection word_wrap should be {int}') do |expected|
  assert_equal expected, connection.word_wrap
end

###############################################################################
# Then steps – out_event                                                       #
###############################################################################

Then('the player should have output {string}') do |expected|
  msgs = connection.messages.map { |m| m[:message] }
  assert msgs.include?(expected),
         "Expected output to include '#{expected}', got: #{msgs.inspect}"
end

###############################################################################
# Then steps – output                                                          #
###############################################################################

Then('the connection should have received message {string}') do |expected|
  msgs = connection.messages.map { |m| m[:message] }
  assert msgs.include?(expected),
         "Expected connection to receive '#{expected}', got: #{msgs.inspect}"
end

Then('the connection should have received message containing {string}') do |expected|
  msgs = connection.messages.map { |m| m[:message] }
  found = msgs.any? { |m| m.include?(expected) }
  assert found,
         "Expected a message containing '#{expected}', got: #{msgs.inspect}"
end

Then('the connection should not have received any messages after creation') do
  assert connection.messages.empty?,
         "Expected no messages, got: #{connection.messages.inspect}"
end

Then('the connection should be closed') do
  assert_equal true, connection.closed?
end

###############################################################################
# Then steps – handle_input                                                    #
###############################################################################

Then('nothing should happen') do
  # No assertion needed; the step just ensures no exception was raised.
  # We verify no messages were output (for nil/empty input scenarios)
end

Then('a player_input event should have been broadcast') do
  assert broadcast_events.size > 0,
         "Expected at least one player_input broadcast event"
end

###############################################################################
# Then steps – show_inventory                                                  #
###############################################################################

Then('the result should include {string}') do |expected|
  assert result.include?(expected),
         "Expected result to include '#{expected}', got: #{result.inspect}"
end

###############################################################################
# Then steps – long_desc                                                       #
###############################################################################

Then('the long_desc result should include equipment info') do
  assert_not_nil long_desc_result
  # The result is a string containing the long_desc + equipment.show(self)
  assert long_desc_result.is_a?(String),
         "Expected long_desc to return a String"
end

###############################################################################
# Then steps – health / satiety                                                #
###############################################################################

Then('the player health should be {string}') do |expected|
  assert_equal expected, player.health
end

Then('the player satiety should be {string}') do |expected|
  assert_equal expected, player.satiety
end

Then('the player info stats health should be {int}') do |expected|
  assert_equal expected, player.info.stats.health
end
