Feature: Canonical hexadecimal representation of a GUID
  In order to safely serialise GUIDs
  As a library consumer
  I want Guid#hexdigest to emit a 32-character canonical hex string
  And that value should equal the dashed string form stripped of its dashes

  Background:
    Given I require the GUID library
    And I generate 5 GUIDs

  Scenario: Hexdigest format and equality invariants
    Then each GUID's hexdigest should be 32 hexadecimal characters
    And each GUID's hexdigest should match its string representation without dashes 