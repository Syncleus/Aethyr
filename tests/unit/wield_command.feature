Feature: WieldCommand action
  In order to let players wield weapons
  As a maintainer of the Aethyr engine
  I want WieldCommand#action to correctly handle all wield scenarios.

  Background:
    Given a stubbed WieldCommand environment

  # --- weapon not in inventory, not in equipment ---
  Scenario: Weapon not found anywhere outputs "What are you trying to wield?"
    Given the player has no weapon in inventory or equipment
    When the WieldCommand action is invoked
    Then the wield player should see "What are you trying to wield?"

  # --- weapon not in inventory, found in equipment and already wielded ---
  Scenario: Weapon already wielded outputs "You are already wielding that."
    Given the player has the weapon equipped and already wielded
    When the WieldCommand action is invoked
    Then the wield player should see "You are already wielding that."

  # --- weapon not in inventory, found in equipment but NOT wielded ---
  Scenario: Weapon in equipment but not wielded outputs "What are you trying to wield?"
    Given the player has the weapon equipped but not wielded
    When the WieldCommand action is invoked
    Then the wield player should see "What are you trying to wield?"

  # --- weapon in inventory but not a Weapon class ---
  Scenario: Non-weapon item outputs "is not wieldable"
    Given the player has a non-weapon item in inventory
    When the WieldCommand action is invoked
    Then the wield player should see "is not wieldable"

  # --- side specified but invalid ---
  Scenario: Invalid side outputs "Which hand?"
    Given the player has a weapon in inventory
    And the wield side is "middle"
    When the WieldCommand action is invoked
    Then the wield player should see "Which hand?"

  # --- valid side but check_wield fails ---
  Scenario: Side specified but check_wield fails outputs error
    Given the player has a weapon in inventory
    And the wield side is "right"
    And check_wield will return "You are already wielding something in that hand."
    When the WieldCommand action is invoked
    Then the wield player should see "You are already wielding something in that hand."

  # --- valid side, check_wield ok, wear fails ---
  Scenario: Side specified, check_wield ok, but wear fails
    Given the player has a weapon in inventory
    And the wield side is "left"
    And check_wield will return nil
    And wear will return nil
    When the WieldCommand action is invoked
    Then the wield player should see "You are unable to wield that."

  # --- valid side, check_wield ok, wear succeeds ---
  Scenario: Side specified, wield succeeds
    Given the player has a weapon in inventory
    And the wield side is "right"
    And check_wield will return nil
    And wear will return a position
    When the WieldCommand action is invoked
    Then the wield event to_player should contain "You grip"
    And the wield event to_player should contain "firmly in your right hand"
    And the wield event to_other should contain "wields"
    And the weapon should be removed from inventory
    And the room should receive out_event

  # --- no side, check_wield fails ---
  Scenario: No side, check_wield fails outputs error
    Given the player has a weapon in inventory
    And check_wield will return "You need an empty hand."
    When the WieldCommand action is invoked
    Then the wield player should see "You need an empty hand."

  # --- no side, check_wield ok, wear fails ---
  Scenario: No side, check_wield ok, but wear fails
    Given the player has a weapon in inventory
    And check_wield will return nil
    And wear will return nil
    When the WieldCommand action is invoked
    Then the wield player should see "You are unable to wield that weapon."

  # --- no side, check_wield ok, wear succeeds ---
  Scenario: No side, wield succeeds
    Given the player has a weapon in inventory
    And check_wield will return nil
    And wear will return a position
    When the WieldCommand action is invoked
    Then the wield event to_player should contain "You firmly grip"
    And the wield event to_player should contain "and begin to wield it"
    And the wield event to_other should contain "wields"
    And the weapon should be removed from inventory
    And the room should receive out_event
