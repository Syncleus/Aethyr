Feature: RemoveCommand action
  In order to let players remove equipment
  As a maintainer of the Aethyr engine
  I want RemoveCommand#action to correctly handle all remove scenarios.

  Background:
    Given a stubbed RemoveCommand environment

  # --- object not found in equipment ---
  Scenario: Object not found in equipment
    Given the remove equipment find returns nil for "helmet"
    When the RemoveCommand action is invoked with object "helmet"
    Then the remove player should see "What helmet are you trying to remove?"

  # --- inventory is full ---
  Scenario: Inventory is full
    Given the remove equipment find returns an item called "chestplate"
    And the remove player inventory is full
    When the RemoveCommand action is invoked with object "chestplate"
    Then the remove player should see "There is no room in your inventory."

  # --- object is a Weapon ---
  Scenario: Object is a Weapon
    Given the remove equipment find returns a weapon for "dagger"
    And the remove player inventory is not full
    When the RemoveCommand action is invoked with object "dagger"
    Then the remove player should see "You must unwield weapons."

  # --- successful remove ---
  Scenario: Successful remove
    Given the remove equipment find returns an item called "gauntlets"
    And the remove player inventory is not full
    And the remove player remove will return true
    When the RemoveCommand action is invoked with object "gauntlets"
    Then the remove event to_player should contain "You remove gauntlets."
    And the remove event to_other should contain "removes gauntlets."
    And the remove room should receive out_event

  # --- failed remove ---
  Scenario: Failed remove
    Given the remove equipment find returns an item called "cursed_ring"
    And the remove player inventory is not full
    And the remove player remove will return false
    When the RemoveCommand action is invoked with object "cursed_ring"
    Then the remove player should see "Could not remove cursed_ring for some reason."
