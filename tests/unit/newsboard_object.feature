Feature: Newsboard object
  The Newsboard extension object initialises with correct default attributes.

  Scenario: Newsboard initialises with correct name
    Given I require the Newsboard object library
    When I create a new Newsboard object
    Then the Newsboard name should be "newsboard"

  Scenario: Newsboard initialises with correct generic
    Given I require the Newsboard object library
    When I create a new Newsboard object
    Then the Newsboard generic should be "newsboard"

  Scenario: Newsboard initialises with correct alt_names
    Given I require the Newsboard object library
    When I create a new Newsboard object
    Then the Newsboard alt_names should include "board"
    And the Newsboard alt_names should include "bulletin board"
    And the Newsboard alt_names should include "notice board"
    And the Newsboard alt_names should include "messageboard"

  Scenario: Newsboard is not movable
    Given I require the Newsboard object library
    When I create a new Newsboard object
    Then the Newsboard should not be movable

  Scenario: Newsboard initialises with correct board_name
    Given I require the Newsboard object library
    When I create a new Newsboard object
    Then the Newsboard board_name should be "A Nice Board"

  Scenario: Newsboard initialises with correct announce_new
    Given I require the Newsboard object library
    When I create a new Newsboard object
    Then the Newsboard announce_new should be "An excited voice shouts, \"Someone wrote a new post!\""

  Scenario: Newsboard is an instance of GameObject
    Given I require the Newsboard object library
    When I create a new Newsboard object
    Then the Newsboard should be a kind of GameObject
