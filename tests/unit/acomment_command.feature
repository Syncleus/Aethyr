Feature: AcommentCommand action
  In order to let admins add comments to game objects at runtime
  As a maintainer of the Aethyr engine
  I want AcommentCommand#action to correctly set comments on game objects.

  Background:
    Given a stubbed acomment_cmd environment

  # --- constructor (line 9) ---------------------------------------------------
  Scenario: AcommentCommand can be instantiated
    Then the acomment_cmd should be instantiated successfully

  # --- object found => set comment (lines 15-20, 23-24) -----------------------
  Scenario: Setting a comment on a found object
    Given the acomment_cmd target is "sword"
    And acomment_cmd find_object returns an acomment_cmd object named "Rusty Sword"
    And acomment_cmd comment is "needs balancing"
    When the acomment_cmd action is invoked
    Then the acomment_cmd object comment should be "needs balancing"
    And the acomment_cmd player should see "Added comment:"
    And the acomment_cmd player should see "needs balancing"

  # --- object not found => error message (lines 18-20) ------------------------
  Scenario: Object not found produces an error message
    Given the acomment_cmd target is "ghost"
    And acomment_cmd find_object returns nil
    And acomment_cmd comment is "some comment"
    When the acomment_cmd action is invoked
    Then the acomment_cmd player should see "Cannot find:"
    And the acomment_cmd player should see "ghost"
