Feature: AlogCommand action
  In order to let admins view and configure server logging at runtime
  As a maintainer of the Aethyr engine
  I want AlogCommand#action to correctly dispatch log operations.

  Background:
    Given a stubbed AlogCommand environment

  # --- initialize (line 9) + nil command (lines 15-19) ------------------------
  Scenario: Nil command produces a help message
    Given the alog command is not set
    When the AlogCommand action is invoked
    Then the alog player should see "What do you want to do with the log?"

  # --- "player" branch with value (lines 21, 24, 26-27, 32) ------------------
  Scenario: Viewing player log with a specific number of lines
    Given the alog command is "player"
    And the alog value is "20"
    When the AlogCommand action is invoked
    Then the alog player should see "player.log"

  # --- "players" branch without value (lines 26, 29, 32) ----------------------
  Scenario: Viewing player log with default lines
    Given the alog command is "players"
    When the AlogCommand action is invoked
    Then the alog player should see "player.log"

  # --- "server" branch with value (lines 34-35, 40) --------------------------
  Scenario: Viewing server log with a specific number of lines
    Given the alog command is "server"
    And the alog value is "15"
    When the AlogCommand action is invoked
    Then the alog player should see "server.log"

  # --- "server" branch without value (lines 34, 37, 40) ----------------------
  Scenario: Viewing server log with default lines
    Given the alog command is "server"
    When the AlogCommand action is invoked
    Then the alog player should see "server.log"

  # --- "system" branch with value (lines 42-43, 48, 50) ----------------------
  Scenario: Viewing system log with a specific number of lines
    Given the alog command is "system"
    And the alog value is "25"
    When the AlogCommand action is invoked
    Then the alog player should see "system.log"
    And the global LOG should have been dumped

  # --- "system" branch without value (lines 42, 45, 48, 50) ------------------
  Scenario: Viewing system log with default lines
    Given the alog command is "system"
    When the AlogCommand action is invoked
    Then the alog player should see "system.log"
    And the global LOG should have been dumped

  # --- "flush" branch (lines 52-54) ------------------------------------------
  Scenario: Flushing log to disk
    Given the alog command is "flush"
    When the AlogCommand action is invoked
    Then the alog player should see "Flushed log to disk."
    And the global LOG should have been dumped

  # --- "ultimate" branch (lines 56-57) ---------------------------------------
  Scenario: Setting log level to ultimate
    Given the alog command is "ultimate"
    When the AlogCommand action is invoked
    Then the alog player should see "Log level now set to ULTIMATE."
    And the alog server config log_level should be 3

  # --- "high" branch (lines 59-60) -------------------------------------------
  Scenario: Setting log level to high
    Given the alog command is "high"
    When the AlogCommand action is invoked
    Then the alog player should see "Log level now set to high."
    And the alog server config log_level should be 2

  # --- "low" branch (lines 62-63) --------------------------------------------
  Scenario: Setting log level to low
    Given the alog command is "low"
    When the AlogCommand action is invoked
    Then the alog player should see "Log level now set to normal."
    And the alog server config log_level should be 1

  # --- "normal" branch (lines 62-63) -----------------------------------------
  Scenario: Setting log level to normal
    Given the alog command is "normal"
    When the AlogCommand action is invoked
    Then the alog player should see "Log level now set to normal."
    And the alog server config log_level should be 1

  # --- "off" branch (lines 65-66) --------------------------------------------
  Scenario: Turning logging off
    Given the alog command is "off"
    When the AlogCommand action is invoked
    Then the alog player should see "Logging mostly turned off."
    And the alog server config log_level should be 0

  # --- "debug" branch (lines 68-69) ------------------------------------------
  Scenario: Toggling debug mode
    Given the alog command is "debug"
    When the AlogCommand action is invoked
    Then the alog player should see "Debug info is now:"

  # --- else branch (line 71) -------------------------------------------------
  Scenario: Unknown command produces usage message
    Given the alog command is "nonsense"
    When the AlogCommand action is invoked
    Then the alog player should see "Possible settings: Off, Debug, Normal, High, or Ultimate"
