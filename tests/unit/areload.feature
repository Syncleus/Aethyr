Feature: Areload command action
  In order to hot-reload Ruby source files at runtime
  As a developer of the Aethyr engine
  I want the AreloadCommand to load a file and report the result.

  Background:
    Given a stubbed AreloadCommand environment

  Scenario: Successfully reload an existing file
    Given a temporary Ruby file to reload
    When the AreloadCommand action is invoked with the temp file
    Then the areload player should see "Reloaded"
    And the areload player should see ": true"

  Scenario: Fail to reload a nonexistent file
    When the AreloadCommand action is invoked with a nonexistent file
    Then the areload player should see "Unable to load"
