Feature: Event Sourcing Configuration
  The Aethyr::EventSourcing::Configuration class manages ImmuDB connection
  settings and event sourcing parameters using a singleton pattern. It reads
  from environment variables with sensible defaults and validates all values.

  Scenario: Loading with default configuration values
    Given I create a fresh Configuration instance with default env
    Then the configuration immudb_host should be "localhost"
    And the configuration immudb_port should be 3322
    And the configuration immudb_user should be "immudb"
    And the configuration immudb_pass should be "immudb"
    And the configuration snapshot_frequency should be 500
    And the configuration retry_attempts should be 5
    And the configuration retry_base_delay should be 0.1
    And the configuration retry_max_delay should be 5.0

  Scenario: Loading with custom environment variables
    Given I create a fresh Configuration instance with custom env
    Then the configuration immudb_host should be "custom-host"
    And the configuration immudb_port should be 5555
    And the configuration immudb_user should be "admin"
    And the configuration immudb_pass should be "secret"
    And the configuration snapshot_frequency should be 1000
    And the configuration retry_attempts should be 10
    And the configuration retry_base_delay should be 0.5
    And the configuration retry_max_delay should be 30.0

  Scenario: Accessing configuration via the singleton instance method
    Given I obtain the Configuration singleton instance
    Then the singleton instance should be a Configuration
    And obtaining the instance again should return the same object

  Scenario: Hash-like access for immudb_host
    Given I create a fresh Configuration instance with default env
    Then accessing config key :immudb_host should return "localhost"

  Scenario: Hash-like access for immudb_port
    Given I create a fresh Configuration instance with default env
    Then accessing config key :immudb_port should return 3322

  Scenario: Hash-like access for immudb_user
    Given I create a fresh Configuration instance with default env
    Then accessing config key :immudb_user should return "immudb"

  Scenario: Hash-like access for immudb_pass
    Given I create a fresh Configuration instance with default env
    Then accessing config key :immudb_pass should return "immudb"

  Scenario: Hash-like access for snapshot_frequency
    Given I create a fresh Configuration instance with default env
    Then accessing config key :snapshot_frequency should return 500

  Scenario: Hash-like access for retry_attempts
    Given I create a fresh Configuration instance with default env
    Then accessing config key :retry_attempts should return 5

  Scenario: Hash-like access for retry_base_delay
    Given I create a fresh Configuration instance with default env
    Then accessing config key :retry_base_delay should return 0.1

  Scenario: Hash-like access for retry_max_delay
    Given I create a fresh Configuration instance with default env
    Then accessing config key :retry_max_delay should return 5.0

  Scenario: Hash-like access with an unknown key raises an error
    Given I create a fresh Configuration instance with default env
    When I access an unknown configuration key :bogus
    Then a configuration ArgumentError should be raised with message "Unknown configuration key: bogus"

  Scenario: Generating the ImmuDB address string
    Given I create a fresh Configuration instance with default env
    Then the immudb_address should be "localhost:3322"

  Scenario: Generating connection parameters hash
    Given I create a fresh Configuration instance with default env
    Then the connection_params should include address "localhost:3322"
    And the connection_params should include username "immudb"
    And the connection_params should include password "immudb"

  Scenario: Human-readable to_s output
    Given I create a fresh Configuration instance with default env
    Then the to_s output should contain "Aethyr Event Sourcing Configuration"
    And the to_s output should contain "ImmuDB Host: localhost"
    And the to_s output should contain "ImmuDB Port: 3322"
    And the to_s output should contain "ImmuDB User: immudb"
    And the to_s output should contain masked password
    And the to_s output should contain "Snapshot Frequency: 500"
    And the to_s output should contain "Retry Attempts: 5"

  Scenario: Validation rejects empty host
    When I create a Configuration with empty immudb_host
    Then a configuration ArgumentError should have been raised with message "ImmuDB host cannot be empty"

  Scenario: Validation rejects nil host
    When I create a Configuration with nil immudb_host
    Then a configuration ArgumentError should have been raised with message "ImmuDB host cannot be empty"

  Scenario: Validation rejects port below 1
    When I create a Configuration with immudb_port 0
    Then a configuration ArgumentError should have been raised with message "ImmuDB port must be between 1 and 65535"

  Scenario: Validation rejects port above 65535
    When I create a Configuration with immudb_port 70000
    Then a configuration ArgumentError should have been raised with message "ImmuDB port must be between 1 and 65535"

  Scenario: Validation rejects empty user
    When I create a Configuration with empty immudb_user
    Then a configuration ArgumentError should have been raised with message "ImmuDB user cannot be empty"

  Scenario: Validation rejects empty password
    When I create a Configuration with empty immudb_pass
    Then a configuration ArgumentError should have been raised with message "ImmuDB password cannot be empty"

  Scenario: Validation rejects zero snapshot frequency
    When I create a Configuration with snapshot_frequency 0
    Then a configuration ArgumentError should have been raised with message "Snapshot frequency must be positive"

  Scenario: Validation rejects negative retry attempts
    When I create a Configuration with retry_attempts -1
    Then a configuration ArgumentError should have been raised with message "Retry attempts must be non-negative"

  Scenario: Validation rejects non-positive retry base delay
    When I create a Configuration with retry_base_delay 0
    Then a configuration ArgumentError should have been raised with message "Retry base delay must be positive"

  Scenario: Validation rejects max delay not greater than base delay
    When I create a Configuration with retry_max_delay not greater than base delay
    Then a configuration ArgumentError should have been raised with message "Retry max delay must be greater than base delay"
