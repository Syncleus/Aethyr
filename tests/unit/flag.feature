Feature: Flag object behaviour
  Flags are attached to game objects to alter their properties.
  Each Flag stores metadata and can optionally negate other flags.

  Scenario: Initialize a Flag with all attributes
    Given I create a Flag with affected "strength" and id 1 and name "buff" and affect_desc "increases strength" and help_desc "a strength buff"
    Then the flag affected should be "strength"
    And the flag id should be 1
    And the flag name should be "buff"
    And the flag affect_desc should be "increases strength"
    And the flag help_desc should be "a strength buff"

  Scenario: can_see? returns true for any player
    Given I create a Flag with affected "speed" and id 2 and name "haste" and affect_desc "faster" and help_desc "speed up"
    Then the flag should be visible to any player

  Scenario: negate_flags with nil flags_to_negate returns other_flags unchanged
    Given I create a Flag with affected "armor" and id 3 and name "shield" and affect_desc "blocks" and help_desc "defense" and no flags to negate
    When I negate flags from the list "fire,ice,wind"
    Then the negated flags list should be "fire,ice,wind"

  Scenario: negate_flags with empty flags_to_negate returns other_flags unchanged
    Given I create a Flag with affected "armor" and id 4 and name "ward" and affect_desc "wards" and help_desc "protection" and empty flags to negate
    When I negate flags from the list "fire,ice,wind"
    Then the negated flags list should be "fire,ice,wind"

  Scenario: negate_flags removes matching flags from other_flags
    Given I create a Flag with affected "resist" and id 5 and name "resist" and affect_desc "resists" and help_desc "resistance" and flags to negate "fire,ice"
    When I negate flags from the list "fire,ice,wind,earth"
    Then the negated flags list should be "wind,earth"
