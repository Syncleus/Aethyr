Feature: Player connection lifecycle
  The PlayerConnection class manages the network connection for
  players joining the MUD.  It handles initialization, I/O,
  banner display, expect callbacks, menus, and teardown.

  # ------------------------------------------------------------------
  # Initialization
  # ------------------------------------------------------------------

  Scenario: player connection initializes with an intro banner file
    Given a player connection mock environment with intro file
    When a new player connection is created with intro banner
    Then the player connection should store the socket
    And the player connection in_buffer should be empty
    And the player connection word_wrap should be 120
    And the player connection should not be closed
    And the player connection should have called show_initial

  Scenario: player connection initializes without an intro banner file
    Given a player connection mock environment without intro file
    When a new player connection is created without intro banner
    Then the player connection should store the socket
    And the player connection should not be closed

  Scenario: player connection banner handles IOError on write
    Given a player connection mock environment with io error socket
    When a new player connection is created with io error socket
    Then the player connection should not be closed

  Scenario: player connection banner handles WaitWritable on write
    Given a player connection mock environment with wait writable socket
    When a new player connection is created with wait writable socket
    Then the player connection should store the socket

  # ------------------------------------------------------------------
  # Output methods
  # ------------------------------------------------------------------

  Scenario: player connection send_puts capitalizes and prints
    Given an allocated player connection
    When player connection send_puts is called with "hello world"
    Then the player connection display should have received the message

  Scenario: player connection send_puts with no_newline flag
    Given an allocated player connection
    When player connection send_puts is called with "test" and no_newline
    Then the player connection display should have received the message

  Scenario: player connection output alias delegates to send_puts
    Given an allocated player connection
    When player connection output is called with "alias test"
    Then the player connection display should have received the message

  Scenario: player connection say alias delegates to send_puts
    Given an allocated player connection
    When player connection say is called with "say test"
    Then the player connection display should have received the message

  Scenario: player connection print sends to display
    Given an allocated player connection
    When player connection print is called with "raw message"
    Then the player connection display should have received the message

  Scenario: player connection print does nothing when closed
    Given an allocated player connection that is closed
    When player connection print is called with "ignored"
    Then the player connection display should not have received any message

  Scenario: player connection put_list sends multiple messages
    Given an allocated player connection
    When player connection put_list is called with "one" and "two"
    Then the player connection put_list should have completed without error

  # ------------------------------------------------------------------
  # Expect / ask / ask_menu callbacks
  # ------------------------------------------------------------------

  Scenario: player connection expect stores a callback
    Given an allocated player connection
    When player connection expect is set with a block
    Then the player connection expect callback should be stored

  Scenario: player connection ask outputs question and sets expect
    Given an allocated player connection
    When player connection ask is called with "Pick a name?"
    Then the player connection display should have received the message
    And the player connection expect callback should be stored

  Scenario: player connection ask callback invokes the provided block
    Given an allocated player connection
    When player connection ask is called and then answered with "Arthur"
    Then the player connection ask answer should be "Arthur"

  Scenario: player connection ask_menu with valid answer
    Given an allocated player connection with mock player
    When player connection ask_menu is called with a valid answer "1"
    Then the player connection ask_menu result should be "1"

  Scenario: player connection ask_menu with invalid answer re-prompts
    Given an allocated player connection with mock player
    When player connection ask_menu is called with an invalid answer "bad"
    Then the player connection ask_menu should have re-prompted

  # ------------------------------------------------------------------
  # page_height delegation
  # ------------------------------------------------------------------

  Scenario: player connection page_height delegates to player
    Given an allocated player connection with mock player
    When player connection page_height is called
    Then the player connection page_height should be 40

  # ------------------------------------------------------------------
  # State queries
  # ------------------------------------------------------------------

  Scenario: player connection closed? returns false initially
    Given an allocated player connection
    Then the player connection should not be closed

  Scenario: player connection closed? returns true after close
    Given an allocated player connection
    When player connection close is called
    Then the player connection should be closed

  # ------------------------------------------------------------------
  # close
  # ------------------------------------------------------------------

  Scenario: player connection close stops the display and marks closed
    Given an allocated player connection
    When player connection close is called
    Then the player connection should be closed
    And the player connection display should have been closed

  # ------------------------------------------------------------------
  # choose (empty method)
  # ------------------------------------------------------------------

  Scenario: player connection choose does nothing
    Given an allocated player connection
    When player connection choose is called with "Pick one" and choices
    Then no error should be raised from player connection choose

  # ------------------------------------------------------------------
  # unbind
  # ------------------------------------------------------------------

  Scenario: player connection unbind with a logged-in player
    Given an allocated player connection with mock player
    And the player connection manager stub is set up
    When player connection unbind is called
    Then the player connection should be marked closed
    And the player connection manager should have dropped the player

  Scenario: player connection unbind without a player
    Given an allocated player connection
    And the player connection manager stub is set up
    When player connection unbind is called
    Then the player connection should be marked closed

  Scenario: player connection unbind with mccp enabled
    Given an allocated player connection with mccp enabled
    And the player connection manager stub is set up
    When player connection unbind is called
    Then the player connection mccp should have been finished

  Scenario: player connection unbind when object not loaded
    Given an allocated player connection with mock player
    And the player connection manager stub with object not loaded
    When player connection unbind is called
    Then the player connection should be marked closed
    And the player connection manager should not have dropped the player
