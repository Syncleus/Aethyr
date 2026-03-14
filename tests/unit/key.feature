Feature: Key game object
  A Key is a movable GameObject used to open doors.

  Scenario: Creating a Key with default arguments
    Given I require the Key library
    When I create a new Key with default arguments
    Then the key generic should be "key"
    And the key movable should be true
    And the key short_desc should be "an unremarkable key"
    And the key should be a kind of GameObject
