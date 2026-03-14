Feature: Container game object
  As a developer of the Aethyr engine
  I want the Container class to manage its inventory correctly
  So that objects can be added, removed, found, and events propagated.

  Background:
    Given a stubbed Container test environment

  # ── alert ─────────────────────────────────────────────────────────────────

  Scenario: Alert propagates event to all objects in the container
    Given two objects are in the container
    When I send an alert event to the container
    Then all objects should have received the alert event

  # ── remove ────────────────────────────────────────────────────────────────

  Scenario: Removing an object from the container
    Given an object is in the container
    When I remove the object from the container
    Then the object should no longer be in the container
    And the removed object container should be nil

  # ── find ──────────────────────────────────────────────────────────────────

  Scenario: Finding an object by name in the container
    Given an object named "sword" is in the container
    When I find "sword" in the container
    Then the find result should be the object named "sword"

  Scenario: Finding an object that does not exist returns nil
    When I find "ghost" in the container
    Then the find result should be nil

  # ── include? ──────────────────────────────────────────────────────────────

  Scenario: Checking inclusion of an existing object
    Given an object is in the container
    When I check if the container includes the object
    Then the include result should be true

  Scenario: Checking inclusion of a missing object
    When I check if the container includes a missing id
    Then the include result should be false

  # ── output ────────────────────────────────────────────────────────────────

  Scenario: Output sends message to all objects in the container
    Given two objects are in the container
    When I send output "Hello" to the container
    Then all objects should have received the output "Hello"

  Scenario: Output skips specified objects
    Given two objects are in the container
    When I send output "Hello" to the container skipping the first object
    Then the first object should not have received the output
    And the second object should have received the output "Hello"

  # ── out_event to_player branch ────────────────────────────────────────────

  Scenario: out_event delivers to player when to_player is set
    Given a player object is in the container
    And another object is in the container
    When I send an out_event with to_player set
    Then the player should have received the out_event
    And the other object should have received the out_event

  # ── out_event to_target branch ────────────────────────────────────────────

  Scenario: out_event delivers to target when to_target is set
    Given a target object is in the container
    And another object is in the container
    When I send an out_event with to_target set
    Then the target should have received the out_event
    And the other object should have received the out_event

  # ── out_event to_player and to_target skip duplicates ─────────────────────

  Scenario: out_event skips player and target during inventory iteration
    Given a player object is in the container
    When I send an out_event with to_player set
    Then the player should have received exactly one out_event

  # ── out_event Reacts branch ───────────────────────────────────────────────

  Scenario: out_event triggers alert on self when container is Reacts
    Given a Reacts-enabled container with an object inside
    When I send an out_event on the Reacts container
    Then the Reacts container should have been alerted

  # ── out_event with skip argument ──────────────────────────────────────────

  Scenario: out_event skips explicitly skipped objects
    Given two objects are in the container
    When I send an out_event skipping the first object
    Then the first object should not have received the out_event
    And the second object should have received the out_event via out_event

  # ── look_inside ───────────────────────────────────────────────────────────

  Scenario: look_inside outputs container contents to the player
    Given an object named "gem" is in the container
    When a player looks inside the container
    Then the player should see the container name and inventory listing

  # ── GridContainer add ─────────────────────────────────────────────────────

  Scenario: GridContainer add places object at a position
    Given a stubbed GridContainer test environment
    When I add an object to the grid container at position 3
    Then the grid object should be in the grid container
    And the grid object container should be the grid container id

  # ── GridContainer find_by_position ────────────────────────────────────────

  Scenario: GridContainer find_by_position returns the object at a position
    Given a stubbed GridContainer test environment
    And an object is added to the grid container at position 5
    When I find by position 5 in the grid container
    Then the grid find result should be the added object

  # ── GridContainer position ────────────────────────────────────────────────

  Scenario: GridContainer position returns the position of an object
    Given a stubbed GridContainer test environment
    And an object is added to the grid container at position 7
    When I query the position of the object in the grid container
    Then the grid position result should be 7
