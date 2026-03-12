Feature: WhereisCommand action
  In order to let players locate objects in the game world
  As a maintainer of the Aethyr engine
  I want WhereisCommand#action to correctly report object locations.

  Background:
    Given a stubbed WhereisCommand environment

  # --- Object not found (lines 19-21) ----------------------------------------
  Scenario: Object not found outputs could not find message
    Given the whereis target object is not found
    When the WhereisCommand action is invoked for "ghost"
    Then the whereis player should see "Could not find ghost."

  # --- Object container nil, can :area, area not nil, area != object (lines 24-27)
  Scenario: Object with no container but in an area reports area
    Given the whereis target object "sword" has no container
    And the whereis target object can area with area id "area_42"
    And the whereis manager resolves area "area_42" to "The Great Forest"
    When the WhereisCommand action is invoked for "sword"
    Then the whereis player should see "sword is in The Great Forest."

  # --- Object container nil, can :area but area is nil (line 29) --------------
  Scenario: Object with no container and nil area reports not in anything
    Given the whereis target object "orb" has no container
    And the whereis target object can area but area is nil
    When the WhereisCommand action is invoked for "orb"
    Then the whereis player should see "orb is not in anything."

  # --- Object container nil, cannot :area (line 29) ---------------------------
  Scenario: Object with no container and cannot area reports not in anything
    Given the whereis target object "gem" has no container
    And the whereis target object cannot area
    When the WhereisCommand action is invoked for "gem"
    Then the whereis player should see "gem is not in anything."

  # --- Object container nil, can :area, area == object (line 29) --------------
  Scenario: Object with no container whose area is itself reports not in anything
    Given the whereis target object "realm" has no container
    And the whereis target object can area with area equal to self
    When the WhereisCommand action is invoked for "realm"
    Then the whereis player should see "realm is not in anything."

  # --- Object has container, container found (lines 32, 36-38) ----------------
  Scenario: Object in a container reports container and recurses
    Given the whereis target object "dagger" has container "chest_99"
    And the whereis manager resolves container "chest_99" to "old chest" with goid "chest_99"
    When the WhereisCommand action is invoked for "dagger" with whereis stubbed
    Then the whereis player should see "dagger is in old chest."
    And the whereis recursive call should have been made

  # --- Object has container, container not found (lines 33-34) ----------------
  Scenario: Object in a container whose container is not found
    Given the whereis target object "ring" has container "box_unknown"
    And the whereis manager returns nil for container "box_unknown"
    When the WhereisCommand action is invoked for "ring"
    Then the whereis player should see "Container for ring not found."
