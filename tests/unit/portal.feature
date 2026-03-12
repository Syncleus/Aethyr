Feature: Portal game object
  A Portal is an Exit variant that players can enter but that does not
  appear in the standard exit list.  It supports customisable entrance,
  exit and portal messages with player-name and pronoun interpolation.

  # -------------------------------------------------------------------
  # Construction (lines 13-17)
  # -------------------------------------------------------------------
  Scenario: Creating a Portal with default arguments
    Given I require the Portal library
    When I create a new Portal with default arguments
    Then the Portal generic should be "portal"
    And the Portal article should be "a"
    And the Portal should not be visible
    And the Portal show_in_look should be "A portal to the unknown stands here."
    And the Portal should be a kind of Exit

  # -------------------------------------------------------------------
  # entrance_message – custom messages (lines 28-30, 32, 34, 36-37)
  # -------------------------------------------------------------------
  Scenario: entrance_message interpolates !name in custom message
    Given I require the Portal library
    And a Portal with a custom entrance_message "!name enters the vortex."
    When I call entrance_message with player "Alice"
    Then the Portal message result should be "Alice enters the vortex."

  Scenario: entrance_message interpolates !pronoun in custom message
    Given I require the Portal library
    And a Portal with a custom entrance_message "!pronoun enters the vortex."
    When I call entrance_message with player "Alice"
    Then the Portal message result should be "she enters the vortex."

  Scenario: entrance_message interpolates !pronoun(:possessive) in custom message
    Given I require the Portal library
    And a Portal with a custom entrance_message "!pronoun(:possessive) path is clear."
    When I call entrance_message with player "Alice"
    Then the Portal message result should be "her path is clear."

  # -------------------------------------------------------------------
  # entrance_message – default messages (lines 42, 44, 46, 48, 50)
  # -------------------------------------------------------------------
  Scenario: entrance_message default with jump action
    Given I require the Portal library
    And a Portal with no custom entrance_message named "dark portal"
    When I call entrance_message with player "Alice" and action "jump"
    Then the Portal message result should be "Alice jumps in over dark portal."

  Scenario: entrance_message default with climb action
    Given I require the Portal library
    And a Portal with no custom entrance_message named "dark portal"
    When I call entrance_message with player "Alice" and action "climb"
    Then the Portal message result should be "Alice comes in, climbing dark portal."

  Scenario: entrance_message default with crawl action
    Given I require the Portal library
    And a Portal with no custom entrance_message named "dark portal"
    When I call entrance_message with player "Alice" and action "crawl"
    Then the Portal message result should be "Alice crawls in through dark portal."

  Scenario: entrance_message default with no action
    Given I require the Portal library
    And a Portal with no custom entrance_message named "dark portal"
    When I call entrance_message with player "Alice"
    Then the Portal message result should be "Alice steps through dark portal."

  # -------------------------------------------------------------------
  # exit_message – custom messages (lines 57-59, 61, 63, 65-66)
  # -------------------------------------------------------------------
  Scenario: exit_message interpolates !name in custom message
    Given I require the Portal library
    And a Portal with a custom exit_message "!name departs through the rift."
    When I call exit_message with player "Bob"
    Then the Portal message result should be "Bob departs through the rift."

  Scenario: exit_message interpolates !pronoun in custom message
    Given I require the Portal library
    And a Portal with a custom exit_message "!pronoun departs through the rift."
    When I call exit_message with player "Bob"
    Then the Portal message result should be "she departs through the rift."

  Scenario: exit_message interpolates !pronoun(:possessive) in custom message
    Given I require the Portal library
    And a Portal with a custom exit_message "!pronoun(:possessive) departure is swift."
    When I call exit_message with player "Bob"
    Then the Portal message result should be "her departure is swift."

  # -------------------------------------------------------------------
  # exit_message – default messages (lines 71, 73, 75, 77, 79)
  # -------------------------------------------------------------------
  Scenario: exit_message default with jump action
    Given I require the Portal library
    And a Portal with no custom exit_message named "shimmer gate"
    When I call exit_message with player "Bob" and action "jump"
    Then the Portal message result should be "Bob jumps over shimmer gate."

  Scenario: exit_message default with climb action
    Given I require the Portal library
    And a Portal with no custom exit_message named "shimmer gate"
    When I call exit_message with player "Bob" and action "climb"
    Then the Portal message result should be "Bob climbs shimmer gate."

  Scenario: exit_message default with crawl action
    Given I require the Portal library
    And a Portal with no custom exit_message named "shimmer gate"
    When I call exit_message with player "Bob" and action "crawl"
    Then the Portal message result should be "Bob crawls out through shimmer gate."

  Scenario: exit_message default with no action
    Given I require the Portal library
    And a Portal with no custom exit_message named "shimmer gate"
    When I call exit_message with player "Bob"
    Then the Portal message result should be "Bob steps through shimmer gate and vanishes."

  # -------------------------------------------------------------------
  # portal_message – custom messages (lines 86-88, 90, 92, 94-95)
  # -------------------------------------------------------------------
  Scenario: portal_message interpolates !name in custom message
    Given I require the Portal library
    And a Portal with a custom portal_message "!name feels a rush of energy."
    When I call portal_message with player "Carol"
    Then the Portal message result should be "Carol feels a rush of energy."

  Scenario: portal_message interpolates !pronoun in custom message
    Given I require the Portal library
    And a Portal with a custom portal_message "!pronoun feels a rush of energy."
    When I call portal_message with player "Carol"
    Then the Portal message result should be "she feels a rush of energy."

  Scenario: portal_message interpolates !pronoun(:possessive) in custom message
    Given I require the Portal library
    And a Portal with a custom portal_message "!pronoun(:possessive) senses tingle."
    When I call portal_message with player "Carol"
    Then the Portal message result should be "her senses tingle."

  # -------------------------------------------------------------------
  # portal_message – default messages (lines 100, 102, 104, 106, 108)
  # -------------------------------------------------------------------
  Scenario: portal_message default with jump action
    Given I require the Portal library
    And a Portal with no custom portal_message named "crystal arch"
    When I call portal_message with player "Carol" and action "jump"
    Then the Portal message result should be "Gathering your strength, you jump over crystal arch."

  Scenario: portal_message default with climb action
    Given I require the Portal library
    And a Portal with no custom portal_message named "crystal arch"
    When I call portal_message with player "Carol" and action "climb"
    Then the Portal message result should be "You reach up and climb crystal arch."

  Scenario: portal_message default with crawl action
    Given I require the Portal library
    And a Portal with no custom portal_message named "crystal arch"
    When I call portal_message with player "Carol" and action "crawl"
    Then the Portal message result should be "You stretch out on your stomach and crawl through crystal arch."

  Scenario: portal_message default with no action
    Given I require the Portal library
    And a Portal with no custom portal_message named "crystal arch"
    When I call portal_message with player "Carol"
    Then the Portal message result should be "You boldly step through crystal arch."

  # -------------------------------------------------------------------
  # peer (line 114)
  # -------------------------------------------------------------------
  Scenario: peer returns the long description
    Given I require the Portal library
    And a Portal with long_desc "A swirling vortex of light."
    When I call peer on the Portal
    Then the Portal message result should be "A swirling vortex of light."
