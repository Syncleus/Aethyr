Feature: Robust error handling for invalid input
  To prevent silent corruption
  Guid must raise descriptive ArgumentErrors when given invalid data

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