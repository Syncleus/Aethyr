Feature: UnwieldCommand action
  In order to let players unwield weapons
  As a maintainer of the Aethyr engine
  I want UnwieldCommand#action to correctly handle all unwield scenarios.

  Background:
    Given a stubbed UnwieldCommand environment

  # --- weapon = "right", get_wielded returns nil ---
  Scenario: Right hand specified but nothing wielded there
    Given the unwield weapon is "right"
    And get_wielded for that hand returns nil
    When the UnwieldCommand action is invoked
    Then the unwield player should see "You are not wielding anything in your right hand."

  # --- weapon = "left", get_wielded returns nil ---
  Scenario: Left hand specified but nothing wielded there
    Given the unwield weapon is "left"
    And get_wielded for that hand returns nil
    When the UnwieldCommand action is invoked
    Then the unwield player should see "You are not wielding anything in your left hand."

  # --- weapon = "right", get_wielded returns weapon, remove succeeds ---
  Scenario: Right hand specified, weapon found, unwield succeeds
    Given the unwield weapon is "right"
    And get_wielded for that hand returns a weapon called "longsword"
    And equipment remove will succeed
    When the UnwieldCommand action is invoked
    Then the unwield event to_player should contain "You unwield longsword."
    And the unwield event to_other should contain "unwields longsword."
    And the unwield room should receive out_event
    And the weapon should be in the unwield player inventory

  # --- weapon = nil, get_wielded returns nil ---
  Scenario: No weapon specified and nothing wielded at all
    Given the unwield weapon is not set
    And get_wielded returns nil
    When the UnwieldCommand action is invoked
    Then the unwield player should see "You are not wielding anything."

  # --- weapon = nil, get_wielded returns a weapon, remove succeeds ---
  Scenario: No weapon specified, wielded weapon found, unwield succeeds
    Given the unwield weapon is not set
    And get_wielded returns a weapon called "battleaxe"
    And equipment remove will succeed
    When the UnwieldCommand action is invoked
    Then the unwield event to_player should contain "You unwield battleaxe."
    And the unwield event to_other should contain "unwields battleaxe."
    And the unwield room should receive out_event
    And the weapon should be in the unwield player inventory

  # --- weapon = named item, find returns nil ---
  Scenario: Named weapon not found in equipment
    Given the unwield weapon is "sword"
    And equipment find returns nil
    When the UnwieldCommand action is invoked
    Then the unwield player should see "What are you trying to unwield?"

  # --- weapon = named item, found but not in wield position ---
  Scenario: Named weapon found but not wielded (worn position)
    Given the unwield weapon is "shield"
    And equipment find returns a weapon called "shield"
    And equipment position_of returns a non-wield position
    When the UnwieldCommand action is invoked
    Then the unwield player should see "You are not wielding shield."

  # --- weapon = named item, found, in wield position, remove succeeds ---
  Scenario: Named weapon found and wielded, unwield succeeds
    Given the unwield weapon is "greatsword"
    And equipment find returns a weapon called "greatsword"
    And equipment position_of returns a wield position
    And equipment remove will succeed
    When the UnwieldCommand action is invoked
    Then the unwield event to_player should contain "You unwield greatsword."
    And the unwield event to_other should contain "unwields greatsword."
    And the unwield room should receive out_event
    And the weapon should be in the unwield player inventory

  # --- weapon = named item, found, in wield position, remove fails ---
  Scenario: Named weapon found and wielded but remove fails
    Given the unwield weapon is "cursed_blade"
    And equipment find returns a weapon called "cursed_blade"
    And equipment position_of returns a wield position
    And equipment remove will fail
    When the UnwieldCommand action is invoked
    Then the unwield player should see "Could not unwield cursed_blade."
