Feature: Globally-Unique Identifiers (GUID)

  In order to reference game-objects reliably
  As a developer of the Aethyr engine
  I want the Guid utility to emit valid, unique identifiers
  So that I can persist and restore objects without collisions

  Background:
    Given I require the GUID library
    And I generate 5 GUIDs

  Scenario: Generate and validate several GUIDs
    Given I require the GUID library
    When I generate 5 GUIDs
    Then each GUID should match the canonical GUID pattern
    And all GUIDs should be unique
    And converting a GUID to and from a string yields the original GUID
    And converting a GUID to and from raw bytes yields the original GUID

  Scenario: Hexdigest format and equality invariants
    Then each GUID's hexdigest should be 32 hexadecimal characters
    And each GUID's hexdigest should match its string representation without dashes 

  Scenario Outline: GUID respects the "<type>" configuration
    Given I require the GUID library
    And I set the GOID type to "<type>"
    When I generate 3 GUIDs
    Then the GOID strings should match the "<type>" pattern
    And I reset the GOID type

    Examples:
      | type       |
      | hex_code   |
      | integer_16 |
      | integer_24 |
      | integer_32 |

  Scenario: Unsupported GOID type reverts to canonical dashed form
    Given I require the GUID library
    And I set the GOID type to "unsupported"
    When I generate 3 GUIDs
    Then the GOID strings should be in canonical dashed form
    And I reset the GOID type 

  Scenario: Parsing an invalid hex string
    Given I require the GUID library
    When I attempt to parse the GUID string "this-is-not-a-valid-guid"
    Then an ArgumentError should be raised with message "Invalid GUID hexstring"

  Scenario: Parsing raw bytes of an invalid length
    Given I require the GUID library
    When I attempt to parse raw GUID bytes of length 15
    Then an ArgumentError should be raised with message "Invalid GUID raw bytes, length must be 16 bytes"

  Scenario: Guid raises when no random device is available
    Given I require the GUID library
    And the system lacks both urandom and random
    Then generating a GUID should raise RuntimeError "Can't find random device"

  Scenario: Guid falls back to random when urandom is missing
    Given I require the GUID library
    And the system is missing urandom but has random
    When I generate 2 GUIDs
    Then each GUID should match the canonical GUID pattern
    And all GUIDs should be unique 

  Scenario: Event supports dynamic attributes and attachment chaining
    Given I require the Event library
    When I create a new event of type "combat" for player "Alice"
    And I add attribute "target" with value "Goblin" to the current event
    Then the current event should have attribute "target" equal to "Goblin"
    When I attach a secondary event of type "damage" with amount 10 to the current event
    Then the current event should contain an attached event of type "damage"
    And converting the current event to string should include "target=Goblin" 