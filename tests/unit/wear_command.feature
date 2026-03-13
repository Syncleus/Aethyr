Feature: WearCommand action
  In order to let players wear equipment from inventory
  As a maintainer of the Aethyr engine
  I want WearCommand#action to correctly handle all wear scenarios.

  Background:
    Given a stubbed WearCommand environment

  # --- object not found in inventory ---
  Scenario: Object not found in inventory
    Given the wear inventory find returns nil for "helmet"
    When the WearCommand action is invoked with object "helmet"
    Then the wear player should see "What helmet are you trying to wear?"

  # --- object is a Weapon ---
  Scenario: Object is a Weapon
    Given the wear inventory find returns a weapon called "dagger"
    When the WearCommand action is invoked with object "dagger"
    Then the wear player should see "You must wield dagger."

  # --- successful wear ---
  Scenario: Successful wear
    Given the wear inventory find returns an item called "chainmail"
    And the wear player wear will return true
    When the WearCommand action is invoked with object "chainmail"
    Then the wear event to_player should contain "You put on chainmail."
    And the wear event to_other should contain "puts on chainmail."
    And the wear room should receive out_event

  # --- failed wear ---
  Scenario: Failed wear
    Given the wear inventory find returns an item called "cursed_helm"
    And the wear player wear will return false
    When the WearCommand action is invoked with object "cursed_helm"
    Then the wear room should not receive out_event
