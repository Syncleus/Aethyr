Feature: ServerConfig utility
  The ServerConfig module loads configuration from a YAML file and exposes
  accessor methods for every setting the Aethyr engine needs at runtime.

  Background:
    Given I require the config library
    And I stub the config file with default values

  # --- ImmuDB defaults -------------------------------------------------------

  Scenario: immudb_address returns default when key is absent
    Given the config hash has no key "immudb_address"
    Then ServerConfig immudb_address should equal "127.0.0.1"

  Scenario: immudb_address returns configured value
    Given the config hash has key "immudb_address" set to "10.0.0.5"
    Then ServerConfig immudb_address should equal "10.0.0.5"

  Scenario: immudb_port returns default when key is absent
    Given the config hash has no key "immudb_port"
    Then ServerConfig immudb_port should equal 3322

  Scenario: immudb_port returns configured value
    Given the config hash has key "immudb_port" set to integer 5555
    Then ServerConfig immudb_port should equal 5555

  Scenario: immudb_username returns default when key is absent
    Given the config hash has no key "immudb_username"
    Then ServerConfig immudb_username should equal "immudb"

  Scenario: immudb_username returns configured value
    Given the config hash has key "immudb_username" set to "admin"
    Then ServerConfig immudb_username should equal "admin"

  Scenario: immudb_password returns default when key is absent
    Given the config hash has no key "immudb_password"
    Then ServerConfig immudb_password should equal "immudb"

  Scenario: immudb_password returns configured value
    Given the config hash has key "immudb_password" set to "secret"
    Then ServerConfig immudb_password should equal "secret"

  Scenario: immudb_database returns default when key is absent
    Given the config hash has no key "immudb_database"
    Then ServerConfig immudb_database should equal "aethyr"

  Scenario: immudb_database returns configured value
    Given the config hash has key "immudb_database" set to "mydb"
    Then ServerConfig immudb_database should equal "mydb"

  # --- Sequent / event sourcing -----------------------------------------------

  Scenario: snapshot_threshold returns default when key is absent
    Given the config hash has no key "snapshot_threshold"
    Then ServerConfig snapshot_threshold should equal 100

  Scenario: snapshot_threshold returns configured value
    Given the config hash has key "snapshot_threshold" set to integer 50
    Then ServerConfig snapshot_threshold should equal 50

  Scenario: event_sourcing_enabled returns default when key is absent
    Given the config hash has no key "event_sourcing_enabled"
    Then ServerConfig event_sourcing_enabled should equal false

  Scenario: event_sourcing_enabled returns configured value
    Given the config hash has key "event_sourcing_enabled" set to boolean true
    Then ServerConfig event_sourcing_enabled should equal true

  # --- Simple accessors -------------------------------------------------------

  Scenario: admin returns the configured admin name
    Given the config hash has key "admin" set to "root"
    Then ServerConfig admin should equal "root"

  Scenario: address returns the configured address
    Given the config hash has key "address" set to "0.0.0.0"
    Then ServerConfig address should equal "0.0.0.0"

  Scenario: intro_file returns the configured intro file path
    Given the config hash has key "intro_file" set to "conf/intro.txt"
    Then ServerConfig intro_file should equal "conf/intro.txt"

  Scenario: log_level returns the configured log level
    Given the config hash has key "log_level" set to integer 2
    Then ServerConfig log_level should equal 2

  Scenario: port returns the configured port
    Given the config hash has key "port" set to integer 8080
    Then ServerConfig port should equal 8080

  Scenario: save_rate returns the configured save rate
    Given the config hash has key "save_rate" set to integer 1440
    Then ServerConfig save_rate should equal 1440

  Scenario: start_room returns the configured start room
    Given the config hash has key "start_room" set to "room_1"
    Then ServerConfig start_room should equal "room_1"

  Scenario: restart_delay returns the configured restart delay
    Given the config hash has key "restart_delay" set to integer 5
    Then ServerConfig restart_delay should equal 5

  Scenario: restart_limit returns the configured restart limit
    Given the config hash has key "restart_limit" set to integer 3
    Then ServerConfig restart_limit should equal 3

  Scenario: update_rate returns the configured update rate
    Given the config hash has key "update_rate" set to integer 60
    Then ServerConfig update_rate should equal 60

  # --- Bracket accessor -------------------------------------------------------

  Scenario: Bracket accessor returns value for existing key
    Given the config hash has key "address" set to "localhost"
    Then ServerConfig bracket accessor for "address" should equal "localhost"

  # --- Bracket setter ---------------------------------------------------------

  Scenario: Bracket setter updates a regular setting and saves
    When I set ServerConfig key "port" to integer 9090
    Then ServerConfig bracket accessor for "port" should equal 9090
    And the config should have been saved

  Scenario: Bracket setter for debug updates $DEBUG
    When I set ServerConfig key "debug" to boolean true
    Then the global DEBUG should be true

  # --- options / has_setting? -------------------------------------------------

  Scenario: options returns all configuration keys
    Then ServerConfig options should include "admin"

  Scenario: has_setting? returns true for existing key
    Given the config hash has key "port" set to integer 8080
    Then ServerConfig has_setting for "port" should be true

  Scenario: has_setting? returns false for missing key
    Given the config hash has no key "nonexistent"
    Then ServerConfig has_setting for "nonexistent" should be false

  # --- load / reload ----------------------------------------------------------

  Scenario: load caches the config and does not re-read file
    Then calling load twice should return the same object

  Scenario: load with force re-reads the file
    Then calling load with force true should re-read the file

  Scenario: reload forces a re-read
    Then calling reload should force re-read the file

  # --- save -------------------------------------------------------------------

  Scenario: save writes configuration to YAML file
    When I call save on ServerConfig
    Then the config should have been saved

  # --- to_s -------------------------------------------------------------------

  Scenario: to_s returns a formatted string of all config entries
    Given the config hash has key "admin" set to "root"
    And the config hash has key "port" set to integer 8080
    Then ServerConfig to_s should contain "admin: root"
    And ServerConfig to_s should contain "port: 8080"
