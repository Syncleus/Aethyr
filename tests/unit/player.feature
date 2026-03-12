Feature: Player object
  The Player class represents a connected player in the MUD,
  managing connection I/O, inventory, health, events, and display.

  # ── Constructor ────────────────────────────────────────────────────
  Scenario: Player initialises with correct defaults
    Given I require the Player library with mock connection
    When I create a new Player with mock connection and goid "player-test-1"
    Then the player admin should be false
    And the player should not be blind
    And the player should not be deaf
    And the player use_color should be nil
    And the player page_height should be nil
    And the player reply_to should be nil
    And the player word_wrap should be 120
    And the player layout should be :basic
    And the player help_library should not be nil
    And the player info stats satiety should be 120
    And the player should have skills
    And the player should have explored rooms including the starting room

  # ── blind? ─────────────────────────────────────────────────────────
  Scenario: blind? returns false by default
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-blind-1"
    Then the player should not be blind

  Scenario: blind? returns true when set
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-blind-2"
    When I set the player blind to true
    Then the player should be blind

  # ── set_connection ─────────────────────────────────────────────────
  Scenario: set_connection updates the player connection
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-setconn-1"
    When I set a new connection on the player
    Then the player io should be the new connection
    And the new connection display should have color_settings set
    And the new connection display should have layout set

  # ── dehydrate ──────────────────────────────────────────────────────
  Scenario: dehydrate removes volatile data and captures layout
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-dehy-1"
    When I dehydrate the player
    Then the dehydrated data should contain the connection under :@player
    And the player layout instance variable should reflect the display layout

  # ── rehydrate ──────────────────────────────────────────────────────
  Scenario: rehydrate restores volatile data
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-rehy-1"
    When I dehydrate and then rehydrate the player
    Then the player help_library should not be nil

  Scenario: rehydrate creates new help_library when nil
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-rehy-2"
    When I dehydrate the player
    And I set the player help_library to nil
    And I rehydrate the player with empty volatile data
    Then the player help_library should not be nil

  # ── layout getter ──────────────────────────────────────────────────
  Scenario: layout returns display layout_type when display exists
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-layout-1"
    When I set the display layout_type to "fancy"
    Then the player layout should return "fancy"

  Scenario: layout returns @layout when display is nil
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-layout-2"
    When I set the player display to nil
    Then the player layout should return :basic

  # ── layout= setter ────────────────────────────────────────────────
  Scenario: layout= updates layout and refreshes display
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-layoutset-1"
    When I set the player layout to "wide"
    Then the display should have layout set to "wide"
    And the display should have been refreshed

  # ── color_settings= ───────────────────────────────────────────────
  Scenario: color_settings= updates both player and display
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-color-1"
    When I set the player color_settings to "bright"
    Then the player color_settings should be "bright"
    And the display color_settings should be "bright"

  # ── has? ───────────────────────────────────────────────────────────
  Scenario: has? checks inventory and equipment
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-has-1"
    Then the player has? "nonexistent" should return nil

  # ── menu ───────────────────────────────────────────────────────────
  Scenario: menu delegates to connection ask_menu
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-menu-1"
    When I call menu on the player with options "Pick one"
    Then the connection ask_menu should have been called

  # ── more ───────────────────────────────────────────────────────────
  Scenario: more delegates to connection more
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-more-1"
    When I call more on the player
    Then the connection more should have been called

  # ── deaf? ──────────────────────────────────────────────────────────
  Scenario: deaf? returns false by default
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-deaf-1"
    Then the player should not be deaf

  Scenario: deaf? returns true when set
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-deaf-2"
    When I set the player deaf to true
    Then the player should be deaf

  # ── balance= ───────────────────────────────────────────────────────
  Scenario: balance= sets the balance value
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-bal-1"
    When I set the player balance to false
    Then the player balance should be false

  # ── io ─────────────────────────────────────────────────────────────
  Scenario: io returns the player connection
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-io-1"
    Then the player io should return the connection

  # ── word_wrap getter ───────────────────────────────────────────────
  Scenario: word_wrap returns the wrap value
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-ww-1"
    Then the player word_wrap should be 120

  # ── word_wrap= setter ──────────────────────────────────────────────
  Scenario: word_wrap= sets wrap on player and connection
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-wwset-1"
    When I set the player word_wrap to 80
    Then the player word_wrap should be 80
    And the connection word_wrap should be 80

  # ── out_event: target == self, normal ───────────────────────────────
  Scenario: out_event with target as self outputs to_target
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-1"
    When I send an out_event where target is self and player is other
    Then the player should have output "hit_target_msg"

  # ── out_event: target == self, blind only ──────────────────────────
  Scenario: out_event with blind target outputs to_blind_target
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-2"
    When I set the player blind to true
    And I send an out_event where target is self and player is other
    Then the player should have output "blind_target_msg"

  # ── out_event: target == self, deaf only ───────────────────────────
  Scenario: out_event with deaf target outputs to_deaf_target
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-3"
    When I set the player deaf to true
    And I send an out_event where target is self and player is other
    Then the player should have output "deaf_target_msg"

  # ── out_event: target == self, deaf and blind ──────────────────────
  Scenario: out_event with deaf and blind target outputs to_deafandblind_target
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-4"
    When I set the player blind to true
    And I set the player deaf to true
    And I send an out_event where target is self and player is other
    Then the player should have output "deafblind_target_msg"

  # ── out_event: player == self ──────────────────────────────────────
  Scenario: out_event with player as self outputs to_player
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-5"
    When I send an out_event where player is self
    Then the player should have output "player_msg"

  # ── out_event: other (not target, not player) ──────────────────────
  Scenario: out_event as other outputs to_other
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-6"
    When I send an out_event where both target and player are other
    Then the player should have output "other_msg"

  # ── out_event: other, blind ────────────────────────────────────────
  Scenario: out_event as blind other outputs to_blind_other
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-7"
    When I set the player blind to true
    And I send an out_event where both target and player are other
    Then the player should have output "blind_other_msg"

  # ── out_event: other, deaf ─────────────────────────────────────────
  Scenario: out_event as deaf other outputs to_deaf_other
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-8"
    When I set the player deaf to true
    And I send an out_event where both target and player are other
    Then the player should have output "deaf_other_msg"

  # ── out_event: other, deaf and blind ───────────────────────────────
  Scenario: out_event as deaf and blind other outputs to_deafandblind_other
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-9"
    When I set the player blind to true
    And I set the player deaf to true
    And I send an out_event where both target and player are other
    Then the player should have output "deafblind_other_msg"

  # ── out_event: custom message_type ─────────────────────────────────
  Scenario: out_event uses custom message_type from event
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-evt-10"
    When I send an out_event where player is self with message_type "combat"
    Then the player should have output "player_msg"

  # ── output: string message ─────────────────────────────────────────
  Scenario: output sends a string message to connection
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-out-1"
    When I call output with "Hello world"
    Then the connection should have received message "Hello world"

  # ── output: array message ──────────────────────────────────────────
  Scenario: output joins array messages with newlines
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-out-2"
    When I call output with an array of "line1" and "line2"
    Then the connection should have received message containing "line1"
    And the connection should have received message containing "line2"

  # ── output: nil message ────────────────────────────────────────────
  Scenario: output returns early for nil message
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-out-3"
    When I call output with nil
    Then the connection should not have received any messages after creation

  # ── output: exception handling ─────────────────────────────────────
  Scenario: output handles exception from connection say
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-out-4"
    When I make the connection say raise an error
    And I call output with "trigger error"
    Then the connection should be closed

  # ── handle_input: nil input ────────────────────────────────────────
  Scenario: handle_input returns early for nil input
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-hi-1"
    When I call handle_input with nil
    Then nothing should happen

  # ── handle_input: empty input ──────────────────────────────────────
  Scenario: handle_input returns early for empty input
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-hi-2"
    When I call handle_input with "   "
    Then nothing should happen

  # ── handle_input: dead player ──────────────────────────────────────
  Scenario: handle_input outputs death message when not alive
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-hi-3"
    When I set the player alive to false
    And I call handle_input with "look"
    Then the connection should have received message containing "dead"

  # ── handle_input: alive player ─────────────────────────────────────
  Scenario: handle_input broadcasts player_input when alive
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-hi-4"
    When I call handle_input with "look around"
    Then a player_input event should have been broadcast

  # ── expect ─────────────────────────────────────────────────────────
  Scenario: expect delegates to connection expect
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-exp-1"
    When I call expect on the player with a block
    Then the connection expect should have been called

  # ── editor ─────────────────────────────────────────────────────────
  Scenario: editor delegates to connection start_editor
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-ed-1"
    When I call editor on the player
    Then the connection start_editor should have been called

  # ── show_inventory ─────────────────────────────────────────────────
  Scenario: show_inventory returns inventory and equipment description
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-inv-1"
    When I call show_inventory on the player
    Then the result should include "You are holding"
    And the result should include "nothing"

  # ── long_desc ──────────────────────────────────────────────────────
  Scenario: long_desc returns long description with equipment
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-ld-1"
    When I call long_desc on the player
    Then the long_desc result should include equipment info

  # ── quit ───────────────────────────────────────────────────────────
  Scenario: quit closes the connection
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-quit-1"
    When I call quit on the player
    Then the connection should be closed

  Scenario: quit does not close already closed connection
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-quit-2"
    When I close the connection manually
    And I call quit on the player
    Then the connection should be closed

  # ── health ─────────────────────────────────────────────────────────
  Scenario: health returns descriptive health string
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-hp-1"
    Then the player health should be "at full health"

  Scenario: health returns partial health description
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-hp-2"
    When I set the player health to 50
    Then the player health should be "slightly wounded"

  # ── satiety ────────────────────────────────────────────────────────
  Scenario: satiety returns descriptive satiety string
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-sat-1"
    Then the player satiety should be "completely stuffed"

  # ── take_damage ────────────────────────────────────────────────────
  Scenario: take_damage reduces health
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-dmg-1"
    When I call take_damage with 30
    Then the player info stats health should be 70

  # ── update_display ─────────────────────────────────────────────────
  Scenario: update_display refreshes watch windows
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-upd-1"
    When I call update_display on the player
    Then the display should have been refreshed

  # ── run: health recovery below threshold ───────────────────────────
  Scenario: run recovers 10 health when well below max
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-run-1"
    When I set the player health to 50
    And I call run on the player
    Then the player info stats health should be 60
    And the display should have been refreshed

  # ── run: health recovery near max ──────────────────────────────────
  Scenario: run sets health to max when close to max
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-run-2"
    When I set the player health to 95
    And I call run on the player
    Then the player info stats health should be 100
    And the display should have been refreshed

  # ── run: health at max does not change ─────────────────────────────
  Scenario: run does not change health when already at max
    Given I require the Player library with mock connection
    And I create a new Player with mock connection and goid "player-run-3"
    When I call run on the player
    Then the player info stats health should be 100
    And the display should have been refreshed
