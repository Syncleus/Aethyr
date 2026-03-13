Feature: AlistCommand action
  In order to let admins list game objects at runtime
  As a maintainer of the Aethyr engine
  I want AlistCommand#action to correctly list objects.

  Background:
    Given a stubbed AlistCommand environment

  # --- match is nil: list all GameObjects (lines 15-19, 27-29, 32, 34)
  Scenario: Listing all objects when match is nil
    Given the alist match is not set
    And the alist manager find_all returns objects
    When the AlistCommand action is invoked
    Then the alist player should see "TestObject1"
    And the alist player should see "TestObject2"

  # --- match is set: list by specific attribute (lines 15-17, 21, 27-29, 32, 34)
  Scenario: Listing objects with a specific match and attribute
    Given the alist match is "name" with attrib "sword"
    And the alist manager find_all returns objects
    When the AlistCommand action is invoked
    Then the alist player should see "TestObject1"
    And the alist player should see "TestObject2"

  # --- objects empty: display nothing found message (lines 15-19, 24-25)
  Scenario: Listing objects when none are found
    Given the alist match is not set
    And the alist manager find_all returns no objects
    When the AlistCommand action is invoked
    Then the alist player should see "Nothing like that to list!"
