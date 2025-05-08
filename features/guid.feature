Feature: Globally-Unique Identifiers (GUID)

  In order to reference game-objects reliably
  As a developer of the Aethyr engine
  I want the Guid utility to emit valid, unique identifiers
  So that I can persist and restore objects without collisions

  Scenario: Generate and validate several GUIDs
    Given I require the GUID library
    When I generate 5 GUIDs
    Then each GUID should match the canonical GUID pattern
    And all GUIDs should be unique
    And converting a GUID to and from a string yields the original GUID
    And converting a GUID to and from raw bytes yields the original GUID
