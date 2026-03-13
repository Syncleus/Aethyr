Feature: GaitCommand action
  In order to let players customize their walking gait
  As a maintainer of the Aethyr engine
  I want GaitCommand#action to correctly handle all gait scenarios.

  Background:
    Given a stubbed GaitCommand environment

  # --- no phrase, no existing entrance_message (lines 17, 21-22) --------------
  Scenario: No phrase and no existing gait shows walking normally
    Given the gait player has no entrance message
    When the GaitCommand action is invoked with no phrase
    Then the gait player should see "You are walking normally."

  # --- no phrase, has existing entrance_message (lines 17-20) -----------------
  Scenario: No phrase with existing gait shows current gait
    Given the gait player has entrance message "Strutting proudly"
    When the GaitCommand action is invoked with no phrase
    Then the gait player should see "When you move, it looks something like:"
    And the gait player should see "leaves to the north"

  # --- phrase is "none" (lines 24-27) -----------------------------------------
  Scenario: Phrase "none" clears the gait
    Given the gait player has entrance message "Strutting proudly"
    When the GaitCommand action is invoked with phrase "none"
    Then the gait player entrance message should be nil
    And the gait player exit message should be nil
    And the gait player should see "You will now walk normally."

  # --- phrase is "None" mixed case (lines 24-27) ------------------------------
  Scenario: Phrase "None" mixed case also clears the gait
    Given the gait player has entrance message "Strutting proudly"
    When the GaitCommand action is invoked with phrase "None"
    Then the gait player entrance message should be nil
    And the gait player exit message should be nil
    And the gait player should see "You will now walk normally."

  # --- custom phrase (lines 29-30, 32-33) -------------------------------------
  Scenario: Custom phrase sets entrance and exit messages and shows preview
    When the GaitCommand action is invoked with phrase "Skipping merrily"
    Then the gait player entrance message should be "Skipping merrily, !name comes in from !direction."
    And the gait player exit message should be "Skipping merrily, !name leaves to !direction."
    And the gait player should see "When you move, it will now look something like:"
    And the gait player should see "leaves to the north"
