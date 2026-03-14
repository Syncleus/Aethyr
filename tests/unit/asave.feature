Feature: AsaveCommand action
  In order to let admins manually persist game state
  As a maintainer of the Aethyr engine
  I want AsaveCommand#action to trigger a full save and confirm completion.

  Background:
    Given a stubbed AsaveCommand environment

  # --- action method: lines 15-19 ---
  Scenario: Invoking asave triggers save_all and confirms to the player
    When the AsaveCommand action is invoked
    Then the asave player should see "Save complete. Check log for details."
    And the asave manager save_all should have been called
