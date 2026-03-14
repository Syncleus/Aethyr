Feature: Location trait
  The Location module is mixed into Room and Area to provide
  area lookup, flag collection, and terrain type resolution
  by walking the containment hierarchy.

  Background:
    Given a stubbed Location trait test environment

  # --- area (on an Area object) --- line 20
  Scenario: area returns self when called on an Area
    When I create a Location-test Area
    Then the area method should return itself

  # --- area (on a Room object) --- line 21
  Scenario: area delegates to parent_area when called on a Room
    When I create a Location-test Room inside an Area
    Then the area method on the room should return the parent area

  # --- parent_area traverses non-Area containers --- line 30
  Scenario: parent_area traverses intermediate containers to find the Area
    When I create a Location-test Room nested inside a non-Area container inside an Area
    Then parent_area should return the grandparent Area

  # --- parent_area returns nil when loop exhausts --- line 32
  Scenario: parent_area returns nil when no Area exists in the chain
    When I create a Location-test Room inside a non-Area container with no Area above
    Then parent_area should return nil

  # --- flags merges parent area flags with local flags --- lines 39-40, 42
  Scenario: flags merges parent area flags and applies negation
    When I create a Location-test Room with local flags inside an Area with flags
    Then the room flags should include both parent and local flags
    And local flag negation should have been applied

  # --- terrain_type delegates to parent_area when local is nil --- line 47
  Scenario: terrain_type delegates to parent area when local terrain type is nil
    When I create a Location-test Room with nil terrain type inside an Area with terrain type
    Then the room terrain_type should return the parent area terrain type

  # --- terrain_type returns nil when local is nil and no parent --- line 48
  Scenario: terrain_type returns nil when local is nil and no parent area
    When I create a Location-test Room with nil terrain type and no parent area
    Then the room terrain_type should return nil
