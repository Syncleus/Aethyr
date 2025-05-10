Feature: New character creation and initial login
  # Verifies that a player can create a brand-new character using the public
  # login dialogue and successfully reach the in-game prompt.

  Background:
    Given the Aethyr server is running

  Scenario: Creating and logging in as a new character
    When I connect as a client
    Then the connection should succeed
    And I have created and logged in as a new character
    And I disconnect 