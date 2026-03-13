Feature: Info object
  The Info class extends OpenStruct with nested dot-separated key
  access via set, get, and delete, plus custom inspect and to_s output.

  Background:
    Given I require the Info library

  # --- initialize (line 27-29) ---
  Scenario: Creating an empty Info object
    When I create a new Info object
    Then the Info object should not be nil

  Scenario: Creating an Info object from a hash
    When I create an Info object from a hash with key "name" and value "Bob"
    Then the Info get "name" should return "Bob"

  # --- set with simple key (line 46) ---
  Scenario: Setting a simple attribute
    Given I have an Info object
    When I set Info key "color" to value "red"
    Then the Info get "color" should return "red"

  # --- set with nested dot key (lines 41-44) ---
  Scenario: Setting a nested attribute via dot notation
    Given I have an Info object with nested key "address"
    When I set Info key "address.state" to value "WA"
    Then the Info get "address.state" should return "WA"

  # --- get with simple key (line 58) ---
  Scenario: Getting a simple attribute
    Given I have an Info object
    When I set Info key "name" to value "Alice"
    Then the Info get "name" should return "Alice"

  # --- get with nested dot key (lines 53-56) ---
  Scenario: Getting a nested attribute via dot notation
    Given I have an Info object with nested key "address"
    And I set Info key "address.city" to value "Seattle"
    Then the Info get "address.city" should return "Seattle"

  # --- delete with simple key (line 70) ---
  Scenario: Deleting a simple attribute
    Given I have an Info object
    And I set Info key "temp" to value "gone"
    When I delete Info key "temp"
    Then the Info get "temp" should return nil

  # --- delete with nested dot key (lines 65-68) ---
  Scenario: Deleting a nested attribute via dot notation
    Given I have an Info object with nested key "address"
    And I set Info key "address.zip" to value "98101"
    When I delete Info key "address.zip"
    Then the Info get "address.zip" should return nil

  # --- inspect with non-Info value (lines 79, 84, 87) ---
  Scenario: Inspecting an Info object with plain attributes
    Given I have an Info object
    And I set Info key "name" to value "Bob"
    When I call inspect on the Info object
    Then the inspect output should start with "Info:"
    And the inspect output should contain "name:"

  # --- inspect with nested Info value (lines 79, 81-82, 87) ---
  Scenario: Inspecting an Info object with nested Info attributes
    Given I have an Info object with nested key "address"
    And I set Info key "address.city" to value "Seattle"
    When I call inspect on the Info object
    Then the inspect output should start with "Info:"
    And the inspect output should contain "address:"
    And the inspect output should contain "city:"

  # --- to_s (line 94) ---
  Scenario: Converting an Info object to string
    Given I have an Info object
    When I call to_s on the Info object
    Then the to_s output should be "Info object"
