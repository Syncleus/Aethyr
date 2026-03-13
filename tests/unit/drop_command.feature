Feature: DropCommand action
  In order to let players drop items from their inventory
  As a maintainer of the Aethyr engine
  I want DropCommand#action to correctly handle all drop scenarios.

  Background:
    Given a stubbed DropCommand environment

  # --- constructor (line 9) ---------------------------------------------------
  Scenario: DropCommand can be instantiated
    Then the DropCommand should be instantiated successfully

  # --- item found in inventory, successful drop (lines 14-15, 27, 29-30, 32-35)
  Scenario: Successfully drop an item from inventory
    Given drop item "sword" is in player inventory
    When the DropCommand action is invoked with object "sword"
    Then the drop player inventory should not have the item
    And the drop item should be in the room
    And the drop room should have an out_event
    And the drop event to_player should contain "You drop shiny sword."
    And the drop event to_other should contain "TestDropper drops shiny sword."
    And the drop event to_blind_other should be "You hear something hit the ground."

  # --- item not in inventory, worn or wielded (lines 14-15, 17-19, 24) --------
  Scenario: Item not in inventory but worn or wielded
    Given drop item "helmet" is not in player inventory
    And drop equipment reports worn or wielded "You must remove the helmet first." for "helmet"
    When the DropCommand action is invoked with object "helmet"
    Then the drop player should see "You must remove the helmet first."

  # --- item not found anywhere (lines 14-15, 17, 21, 24) ---------------------
  Scenario: Item not in inventory and not worn or wielded
    Given drop item "potion" is not in player inventory
    And drop equipment does not report worn or wielded for "potion"
    When the DropCommand action is invoked with object "potion"
    Then the drop player should see "You have no potion to drop."
