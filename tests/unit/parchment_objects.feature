Feature: Parchment – a readable game object
  As a game engine developer
  I want a Parchment object that includes the Readable trait
  So that players can read parchments in the game world

  Scenario: Creating a Parchment sets sensible defaults
    Given I require the Parchment library
    When a Parchment object is created
    Then the Parchment generic should be "parchment"
    And the Parchment should be movable
    And the Parchment short_desc should be "a piece of parchment"
    And the Parchment long_desc should be "a piece of parchment"
    And the Parchment show_in_look should be "A short piece of parchment is lying on the ground here."
    And the Parchment name should be "a piece of parchment"
    And the Parchment alt_names should include "paper"

  Scenario: Parchment includes the Readable trait
    Given I require the Parchment library
    When a Parchment object is created
    Then the Parchment should respond to readable_text
    And the Parchment actions should include "read"
    And the Parchment readable_text should be nil by default

  Scenario: Parchment is a kind of GameObject
    Given I require the Parchment library
    When a Parchment object is created
    Then the Parchment should be a kind of GameObject
