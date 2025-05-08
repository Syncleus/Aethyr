Feature: Configurable GOID string formats via ServerConfig
  In order to support legacy persistence schemes
  Guid#to_s should honour the global ServerConfig[:goid_type] switch

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