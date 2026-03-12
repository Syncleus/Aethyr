Feature: AlookCommand action
  In order to let admins inspect game objects at runtime
  As a maintainer of the Aethyr engine
  I want AlookCommand#action to correctly display object details.

  Background:
    Given a stubbed AlookCommand environment

  # --- at is nil: look at the room itself (lines 16-19, 31-32, 34, 41, 44, 62-63)
  Scenario: Looking with no target inspects the current room
    Given the alook at target is not set
    When the AlookCommand action is invoked
    Then the alook player should see "Object:"
    And the alook player should see "Attributes:"
    And the alook player should see "Inventory:"
    And the alook output should have been logged

  # --- at is "here": use $manager.find on the container (lines 20-21)
  Scenario: Looking at here inspects via manager find
    Given the alook at target is "here"
    When the AlookCommand action is invoked
    Then the alook player should see "Object:"
    And the alook player should see "Attributes:"

  # --- at is a specific object name found via find_object (line 23)
  Scenario: Looking at a named object found via find_object
    Given the alook at target is "sword"
    And the alook manager can find object "sword"
    When the AlookCommand action is invoked
    Then the alook player should see "Object:"
    And the alook player should see "Attributes:"

  # --- object not found returns error (lines 26-28)
  Scenario: Looking at an unknown object gives an error
    Given the alook at target is "nonexistent"
    And the alook manager cannot find object "nonexistent"
    When the AlookCommand action is invoked
    Then the alook player should see "Cannot find nonexistent to inspect."

  # --- object with inventory (lines 46-48)
  Scenario: Object with inventory lists items
    Given the alook at target is not set
    And the alook room has inventory
    When the AlookCommand action is invoked
    Then the alook player should see "Inventory:"
    And the alook player should see "TestItem"

  # --- object without inventory method (line 51)
  Scenario: Object without inventory shows no inventory
    Given the alook at target is not set
    And the alook room has no inventory method
    When the AlookCommand action is invoked
    Then the alook player should see "No Inventory"

  # --- object with equipment (lines 54-57, 59)
  Scenario: Object with equipment lists equipment
    Given the alook at target is not set
    And the alook room has equipment
    When the AlookCommand action is invoked
    Then the alook player should see "Equipment:"
    And the alook player should see "TestArmor"

  # --- object with @observer_peers instance variable (lines 36-37)
  Scenario: Object with observer_peers formats them
    Given the alook at target is not set
    And the alook room has observer_peers
    When the AlookCommand action is invoked
    Then the alook player should see "@observer_peers ="

  # --- object with @local_registrations instance variable (lines 38-39)
  Scenario: Object with local_registrations formats them
    Given the alook at target is not set
    And the alook room has local_registrations
    When the AlookCommand action is invoked
    Then the alook player should see "@local_registrations ="

  # --- inventory with nil position (line 48 nil branch)
  Scenario: Inventory item with nil position shows no dimensions
    Given the alook at target is not set
    And the alook room has inventory with nil position
    When the AlookCommand action is invoked
    Then the alook player should see "TestItem"
    And the alook inventory line should not contain position dimensions

  # --- inventory with non-nil position (line 48 position branch)
  Scenario: Inventory item with position shows dimensions
    Given the alook at target is not set
    And the alook room has inventory with position
    When the AlookCommand action is invoked
    Then the alook player should see "TestItem"
    And the alook player should see "3x4"
