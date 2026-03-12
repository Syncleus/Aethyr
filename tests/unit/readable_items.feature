Feature: Scroll – a readable, writable game object
  As a game engine developer
  I want a Scroll object that includes the Readable trait
  So that players can read scrolls in the game world

  Scenario: Creating a Scroll sets sensible defaults
    Given I require the Scroll library
    When a Scroll object is created
    Then the Scroll generic should be "scroll"
    And the Scroll should be movable
    And the Scroll short_desc should be "a plain scroll"
    And the Scroll long_desc should be "This is simply a long piece of paper rolled up into a tight tube."
    And the Scroll alt_names should include "plain scroll"
    And the Scroll info writable should be true

  Scenario: Scroll includes the Readable trait
    Given I require the Scroll library
    When a Scroll object is created
    Then the Scroll should respond to readable_text
    And the Scroll actions should include "read"
    And the Scroll readable_text should be nil by default

  Scenario: Scroll is a kind of GameObject
    Given I require the Scroll library
    When a Scroll object is created
    Then the Scroll should be a kind of GameObject

  Scenario: Writing and reading text on a Scroll
    Given I require the Scroll library
    When a Scroll object is created
    And the Scroll readable_text is set to "Ancient secrets lie within."
    Then the Scroll readable_text should equal "Ancient secrets lie within."
