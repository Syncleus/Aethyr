Feature: SitCommand action
  In order to let players sit down
  As a maintainer of the Aethyr engine
  I want SitCommand#action to correctly handle all sit scenarios.

  Background:
    Given a stubbed SitCommand environment

  # --- player not balanced ---
  Scenario: Unbalanced player cannot sit
    Given the sit player is not balanced
    When the SitCommand action is invoked with no object
    Then the sit player should see "You cannot sit properly while unbalanced."

  # --- no object, already sitting ---
  Scenario: Player already sitting outputs already sitting message
    Given the sit player is balanced
    And the sit player is already sitting
    When the SitCommand action is invoked with no object
    Then the sit player should see "You are already sitting down."

  # --- no object, prone and sit succeeds ---
  Scenario: Prone player stands then sits on ground
    Given the sit player is balanced
    And the sit player is prone
    And the sit player can sit
    When the SitCommand action is invoked with no object
    Then the sit event to_player should be "You stand up then sit on the ground."
    And the sit event to_other should contain "stands up then sits down on the ground"
    And the sit room should receive output

  # --- no object, not sitting, not prone, sit succeeds ---
  Scenario: Standing player sits down on ground
    Given the sit player is balanced
    And the sit player is standing
    And the sit player can sit
    When the SitCommand action is invoked with no object
    Then the sit event to_player should be "You sit down on the ground."
    And the sit event to_other should contain "sits down on the ground"
    And the sit room should receive out_event

  # --- no object, not sitting, not prone, sit fails ---
  Scenario: Player unable to sit outputs unable message
    Given the sit player is balanced
    And the sit player is standing
    And the sit player cannot sit
    When the SitCommand action is invoked with no object
    Then the sit player should see "You are unable to sit down."

  # --- object specified, not found ---
  Scenario: Object not found outputs what do you want to sit on
    Given the sit player is balanced
    And the sit target object is not found
    When the SitCommand action is invoked with object "chair"
    Then the sit player should see "What do you want to sit on?"

  # --- object found, not sittable ---
  Scenario: Object is not sittable
    Given the sit player is balanced
    And the sit target object "rock" is not sittable
    When the SitCommand action is invoked with object "rock"
    Then the sit player should see "You cannot sit on rock."

  # --- object found, already occupied by player ---
  Scenario: Object already occupied by player
    Given the sit player is balanced
    And the sit target object "chair" is occupied by the player
    When the SitCommand action is invoked with object "chair"
    Then the sit player should see "You are already sitting there!"

  # --- object found, no room available (singular) ---
  Scenario: Object has no room available singular
    Given the sit player is balanced
    And the sit target object "chair" has no room and is singular
    When the SitCommand action is invoked with object "chair"
    Then the sit player should see "is already occupied."

  # --- object found, no room available (plural) ---
  Scenario: Object has no room available plural
    Given the sit player is balanced
    And the sit target object "benches" has no room and is plural
    When the SitCommand action is invoked with object "benches"
    Then the sit player should see "are already occupied."

  # --- object found, player.sit(object) succeeds ---
  Scenario: Player successfully sits on object
    Given the sit player is balanced
    And the sit target object "chair" is sittable with room
    And the sit player can sit
    When the SitCommand action is invoked with object "chair"
    Then the sit event to_player should be "You sit down on chair."
    And the sit event to_other should contain "sits down on chair"
    And the sit room should receive out_event
    And the sit object should record sat_on_by

  # --- object found, player.sit(object) fails ---
  Scenario: Player unable to sit on object
    Given the sit player is balanced
    And the sit target object "chair" is sittable with room
    And the sit player cannot sit
    When the SitCommand action is invoked with object "chair"
    Then the sit player should see "You are unable to sit down."
