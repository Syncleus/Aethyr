Feature: GiveCommand action
  In order to let players give items to other characters
  As a maintainer of the Aethyr engine
  I want GiveCommand#action to correctly handle all give scenarios.

  Background:
    Given a stubbed GiveCommand environment

  # --- initialize (line 9) + item not found, not worn (lines 14-15, 17, 18, 21, 24) ---
  Scenario: Item not in inventory and not worn or wielded
    Given give item "sword" is not in player inventory
    And give equipment does not report worn or wielded for "sword"
    When the GiveCommand action is invoked with item "sword" to "bob"
    Then the give player should see "You do not seem to have a sword to give away."

  # --- item not found but worn/wielded (lines 14-15, 17, 18-19, 24) ---
  Scenario: Item not in inventory but worn or wielded
    Given give item "helmet" is not in player inventory
    And give equipment reports worn or wielded "You are wearing the helmet." for "helmet"
    When the GiveCommand action is invoked with item "helmet" to "bob"
    Then the give player should see "You are wearing the helmet."

  # --- receiver not found (lines 14-15, 27, 29-31) ---
  Scenario: Item found but receiver not in room
    Given give item "gem" is in player inventory
    And give receiver "bob" is not in room
    When the GiveCommand action is invoked with item "gem" to "bob"
    Then the give player should see "There is no bob."

  # --- receiver is inanimate object (lines 14-15, 27, 32-34) ---
  Scenario: Item found but receiver is an inanimate object
    Given give item "gem" is in player inventory
    And give receiver "statue" is an inanimate object in room
    When the GiveCommand action is invoked with item "gem" to "statue"
    Then the give player should see "You can't give something to an inanimate object."

  # --- successful give to a Player (lines 14-15, 27, 37-38, 40-43, 45) ---
  Scenario: Successfully give item to a Player
    Given give item "gem" is in player inventory
    And give receiver "alice" is a Player in room
    When the GiveCommand action is invoked with item "gem" to "alice"
    Then the give receiver should have the item
    And the give player inventory should not have the item
    And the give room should have an out_event
    And the give event to_player should contain "You give shiny gem to Alice."
    And the give event to_target should contain "gives you shiny gem"
    And the give event to_other should contain "gives shiny gem to Alice."

  # --- successful give to a Mobile (lines 14-15, 27, 37-38, 40-43, 45) ---
  Scenario: Successfully give item to a Mobile
    Given give item "gem" is in player inventory
    And give receiver "goblin" is a Mobile in room
    When the GiveCommand action is invoked with item "gem" to "goblin"
    Then the give receiver should have the item
    And the give player inventory should not have the item
    And the give room should have an out_event
    And the give event to_player should contain "You give shiny gem to Goblin."
    And the give event to_target should contain "gives you shiny gem"
    And the give event to_other should contain "gives shiny gem to Goblin."
