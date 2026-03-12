Feature: PortalCommand action
  In order to let admins configure portal settings at runtime
  As a maintainer of the Aethyr engine
  I want PortalCommand#action to correctly dispatch portal configuration changes.

  Background:
    Given a stubbed PortalCommand environment

  # --- object not found (lines 18-19) ----------------------------------------
  Scenario: Object not found produces an error message
    Given the portal object reference is "nonexistent"
    And portal find_object will return nil
    And the portal setting is "action"
    And the portal value is "enter"
    When the PortalCommand action is invoked
    Then the portal player should see "Cannot find nonexistent"

  # --- object is not a Portal (lines 21-22) -----------------------------------
  Scenario: Object is not a Portal produces an error message
    Given a non-portal target object exists
    And the portal setting is "action"
    And the portal value is "enter"
    When the PortalCommand action is invoked
    Then the portal player should see "That is not a portal."

  # --- setting "action" to "enter" (lines 30-33) -----------------------------
  Scenario: Setting portal action to enter
    Given a portal target object exists
    And the portal setting is "action"
    And the portal value is "enter"
    When the PortalCommand action is invoked
    Then the portal player should see "Set portal action to enter"

  # --- setting "action" to "jump" (lines 34-36) ------------------------------
  Scenario: Setting portal action to jump
    Given a portal target object exists
    And the portal setting is "action"
    And the portal value is "jump"
    When the PortalCommand action is invoked
    Then the portal player should see "Set portal action to jump"

  # --- setting "action" to "climb" (lines 34-36) -----------------------------
  Scenario: Setting portal action to climb
    Given a portal target object exists
    And the portal setting is "action"
    And the portal value is "climb"
    When the PortalCommand action is invoked
    Then the portal player should see "Set portal action to climb"

  # --- setting "action" to "crawl" (lines 34-36) -----------------------------
  Scenario: Setting portal action to crawl
    Given a portal target object exists
    And the portal setting is "action"
    And the portal value is "crawl"
    When the PortalCommand action is invoked
    Then the portal player should see "Set portal action to crawl"

  # --- setting "action" to invalid value (lines 37-38) -----------------------
  Scenario: Setting portal action to invalid value
    Given a portal target object exists
    And the portal setting is "action"
    And the portal value is "fly"
    When the PortalCommand action is invoked
    Then the portal player should see "fly is not a valid portal action."

  # --- setting "exit" to "nil" clears it (lines 41-42, 49) -------------------
  Scenario: Setting exit message to nil clears it
    Given a portal target object exists with exit_message "Old exit msg."
    And the portal setting is "exit"
    And the portal value is "nil"
    When the PortalCommand action is invoked
    Then the portal player should see "exit message set to:"

  # --- setting "exit" to "!nothing" clears it (lines 41-42) ------------------
  Scenario: Setting exit message to !nothing clears it
    Given a portal target object exists with exit_message "Old exit msg."
    And the portal setting is "exit"
    And the portal value is "!nothing"
    When the PortalCommand action is invoked
    Then the portal player should see "exit message set to:"

  # --- setting "exit" with value not ending in punctuation (lines 44-47, 49) --
  Scenario: Setting exit message appends period when no punctuation
    Given a portal target object exists
    And the portal setting is "exit"
    And the portal value is "You leave through the gate"
    When the PortalCommand action is invoked
    Then the portal player should see "exit message set to: You leave through the gate."

  # --- setting "exit" with value ending in punctuation (lines 44, 47, 49) -----
  Scenario: Setting exit message preserves existing punctuation
    Given a portal target object exists
    And the portal setting is "exit"
    And the portal value is "You leave through the gate!"
    When the PortalCommand action is invoked
    Then the portal player should see "exit message set to: You leave through the gate!"

  # --- setting "entrance" to "nil" clears it (lines 51-52, 59) ---------------
  Scenario: Setting entrance message to nil clears it
    Given a portal target object exists with entrance_message "Old entrance msg."
    And the portal setting is "entrance"
    And the portal value is "nil"
    When the PortalCommand action is invoked
    Then the portal player should see "entrance message set to:"

  # --- setting "entrance" to "!nothing" clears it (lines 51-52) ---------------
  Scenario: Setting entrance message to !nothing clears it
    Given a portal target object exists with entrance_message "Old entrance msg."
    And the portal setting is "entrance"
    And the portal value is "!nothing"
    When the PortalCommand action is invoked
    Then the portal player should see "entrance message set to:"

  # --- setting "entrance" with value no punctuation (lines 54-57, 59) ---------
  Scenario: Setting entrance message appends period when no punctuation
    Given a portal target object exists
    And the portal setting is "entrance"
    And the portal value is "Someone arrives through a shimmer"
    When the PortalCommand action is invoked
    Then the portal player should see "entrance message set to: Someone arrives through a shimmer."

  # --- setting "entrance" with value with punctuation (lines 54, 57, 59) ------
  Scenario: Setting entrance message preserves existing punctuation
    Given a portal target object exists
    And the portal setting is "entrance"
    And the portal value is "Someone arrives through a shimmer!"
    When the PortalCommand action is invoked
    Then the portal player should see "entrance message set to: Someone arrives through a shimmer!"

  # --- setting "portal" to "nil" clears it (lines 61-62, 69) -----------------
  Scenario: Setting portal message to nil clears it
    Given a portal target object exists with portal_message "Old portal msg."
    And the portal setting is "portal"
    And the portal value is "nil"
    When the PortalCommand action is invoked
    Then the portal player should see "portal message set to:"

  # --- setting "portal" to "!nothing" clears it (lines 61-62) ----------------
  Scenario: Setting portal message to !nothing clears it
    Given a portal target object exists with portal_message "Old portal msg."
    And the portal setting is "portal"
    And the portal value is "!nothing"
    When the PortalCommand action is invoked
    Then the portal player should see "portal message set to:"

  # --- setting "portal" with value no punctuation (lines 64-67, 69) -----------
  Scenario: Setting portal message appends period when no punctuation
    Given a portal target object exists
    And the portal setting is "portal"
    And the portal value is "You feel a rush of wind"
    When the PortalCommand action is invoked
    Then the portal player should see "portal message set to: You feel a rush of wind."

  # --- setting "portal" with value with punctuation (lines 64, 67, 69) --------
  Scenario: Setting portal message preserves existing punctuation
    Given a portal target object exists
    And the portal setting is "portal"
    And the portal value is "You feel a rush of wind?"
    When the PortalCommand action is invoked
    Then the portal player should see "portal message set to: You feel a rush of wind?"

  # --- unknown setting (lines 70-71) -----------------------------------------
  Scenario: Unknown setting produces a helpful error
    Given a portal target object exists
    And the portal setting is "bogus"
    And the portal value is "whatever"
    When the PortalCommand action is invoked
    Then the portal player should see "Valid options: action, exit, entrance, or portal."
