Feature: AstatusCommand action
  In order to let admins view game status information at runtime
  As a maintainer of the Aethyr engine
  I want AstatusCommand#action to correctly report object counts.

  Background:
    Given a stubbed AstatusCommand environment

  # --- action method: lines 15-21, 23 ---
  Scenario: Displaying status with multiple object types
    Given the astatus manager has object types
      | type    | count |
      | Player  | 3     |
      | Room    | 10    |
      | Item    | 25    |
    And the astatus manager game_objects_count is 38
    When the AstatusCommand action is invoked
    Then the astatus player should see "Object Counts:"
    And the astatus player should see "Player: 3"
    And the astatus player should see "Room: 10"
    And the astatus player should see "Item: 25"
    And the astatus player should see "Total Objects: 38"
    And the astatus awho should have been called

  Scenario: Displaying status with no object types
    Given the astatus manager has no object types
    And the astatus manager game_objects_count is 0
    When the AstatusCommand action is invoked
    Then the astatus player should see "Object Counts:"
    And the astatus player should see "Total Objects: 0"

  Scenario: Displaying status with a single object type
    Given the astatus manager has object types
      | type   | count |
      | Mobile | 7     |
    And the astatus manager game_objects_count is 7
    When the AstatusCommand action is invoked
    Then the astatus player should see "Mobile: 7"
    And the astatus player should see "Total Objects: 7"
