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