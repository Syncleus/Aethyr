Feature: PutCommand action
  In order to let players put items from their inventory into containers
  As a maintainer of the Aethyr engine
  I want PutCommand#action to correctly handle all put scenarios.

  Background:
    Given a stubbed PutCommand environment

  # --- Lines 9, 14-15, 17-19, 24: item nil, equipment returns response ------
  Scenario: Item not found but player is wearing or wielding it
    Given put item "sword" is not in inventory
    And put equipment reports worn or wielded for "sword"
    When the PutCommand action is invoked
    Then the put player should see "You are wearing that"

  # --- Lines 9, 14-15, 17-18, 21, 24: item nil, equipment returns nil ------
  Scenario: Item not found and not equipped either
    Given put item "unicorn" is not in inventory
    And put equipment reports nothing for "unicorn"
    When the PutCommand action is invoked
    Then the put player should see "You do not seem to have a unicorn."

  # --- Lines 9, 14-15, 17, 27, 29-31: item found, container nil ------------
  Scenario: Item found but container not found anywhere
    Given put item "gem" is in inventory
    And put container "chest" is not found anywhere
    When the PutCommand action is invoked
    Then the put player should see "There is no chest in which to put gem."

  # --- Lines 9, 14-15, 17, 27, 29, 32-34: container is not a Container -----
  Scenario: Container found but it is not a Container type
    Given put item "gem" is in inventory
    And put container "rock" is a non-container object
    When the PutCommand action is invoked
    Then the put player should see "You cannot put anything in rock."

  # --- Lines 9, 14-15, 17, 27, 29, 32, 35-37: container closed -------------
  Scenario: Container is a closed openable Container
    Given put item "gem" is in inventory
    And put container "chest" is a closed container
    When the PutCommand action is invoked
    Then the put player should see "You need to open chest first."

  # --- Lines 9, 14-15, 17, 27, 29, 32, 35, 40-41, 43-44, 46: success ------
  Scenario: Successfully putting an item into an open container
    Given put item "gem" is in inventory
    And put container "chest" is an open container
    When the PutCommand action is invoked
    Then the put item should be removed from player inventory
    And the put item should be added to the container
    And the put room should have an out_event with to_player "You put gem in chest."
    And the put room should have an out_event with to_other "TestPutter puts gem in chest"
