Feature: Elemental flag objects
  The elements extension defines eight elemental flag subclasses of Flag.
  Each flag captures an elemental affinity (plus or minus) and stores
  the correct id, name, affect_desc, help_desc, and negation targets.

  Scenario: PlusWater flag initializes with correct attributes
    Given I create a PlusWater element flag with affected "fountain"
    Then the element flag id should be ":plus_water"
    And the element flag name should be "+water"
    And the element flag affect_desc should contain "humid"
    And the element flag help_desc should contain "strong in elemental water"
    And the element flag affected should be "fountain"

  Scenario: MinusWater flag initializes with correct attributes
    Given I create a MinusWater element flag with affected "desert"
    Then the element flag id should be ":minus_water"
    And the element flag name should be "-water"
    And the element flag affect_desc should contain "dry"
    And the element flag help_desc should contain "lacking in elemental water"
    And the element flag affected should be "desert"

  Scenario: PlusEarth flag initializes with correct attributes
    Given I create a PlusEarth element flag with affected "grove"
    Then the element flag id should be ":plus_earth"
    And the element flag name should be "+earth"
    And the element flag affect_desc should contain "alive"
    And the element flag help_desc should contain "strong in elemental earth"
    And the element flag affected should be "grove"

  Scenario: MinusEarth flag initializes with correct attributes
    Given I create a MinusEarth element flag with affected "wasteland"
    Then the element flag id should be ":minus_earth"
    And the element flag name should be "-earth"
    And the element flag affect_desc should contain "barren"
    And the element flag help_desc should contain "lacking in elemental earth"
    And the element flag affected should be "wasteland"

  Scenario: PlusFire flag initializes with correct attributes
    Given I create a PlusFire element flag with affected "volcano"
    Then the element flag id should be ":plus_fire"
    And the element flag name should be "+fire"
    And the element flag affect_desc should contain "hot"
    And the element flag help_desc should contain "strong in elemental fire"
    And the element flag affected should be "volcano"

  Scenario: MinusFire flag initializes with correct attributes
    Given I create a MinusFire element flag with affected "tundra"
    Then the element flag id should be ":minus_fire"
    And the element flag name should be "-fire"
    And the element flag affect_desc should contain "deathly cold"
    And the element flag help_desc should contain "lacking in elemental fire"
    And the element flag affected should be "tundra"

  Scenario: PlusAir flag initializes with correct attributes
    Given I create a PlusAir element flag with affected "hilltop"
    Then the element flag id should be ":plus_air"
    And the element flag name should be "+air"
    And the element flag affect_desc should contain "fresh"
    And the element flag help_desc should contain "strong in elemental air"
    And the element flag affected should be "hilltop"

  Scenario: MinusAir flag initializes with correct attributes
    Given I create a MinusAir element flag with affected "cave"
    Then the element flag id should be ":minus_air"
    And the element flag name should be "-air"
    And the element flag affect_desc should contain "stale"
    And the element flag help_desc should contain "lacking in elemental air"
    And the element flag affected should be "cave"
