Feature: AconfigCommand action
  In order to let admins view and modify server configuration at runtime
  As a maintainer of the Aethyr engine
  I want AconfigCommand#action to correctly handle config viewing, reloading, and setting changes.

  Background:
    Given a stubbed AconfigCommand environment

  # --- setting is nil (lines 18-20) -------------------------------------------
  Scenario: No setting provided shows current configuration
    Given the acfg setting is not provided
    When the AconfigCommand action is invoked
    Then the acfg player should see "Current configuration:"

  # --- setting is "reload" (lines 23, 25-28) ----------------------------------
  Scenario: Reload setting reloads and shows configuration
    Given the acfg setting is "reload"
    When the AconfigCommand action is invoked
    Then the acfg ServerConfig reload should have been called
    And the acfg player should see "Reloaded configuration:"

  # --- setting is "Reload" mixed case (lines 23, 25-28) -----------------------
  Scenario: Reload setting is case-insensitive
    Given the acfg setting is "Reload"
    When the AconfigCommand action is invoked
    Then the acfg ServerConfig reload should have been called
    And the acfg player should see "Reloaded configuration:"

  # --- setting does not exist (lines 29-31) -----------------------------------
  Scenario: Non-existent setting shows error message
    Given the acfg setting is "nonexistent"
    And the acfg ServerConfig does not have that setting
    When the AconfigCommand action is invoked
    Then the acfg player should see "No such setting."

  # --- setting exists with numeric value (lines 34-36, 39, 41) ----------------
  Scenario: Setting a numeric value converts it to integer
    Given the acfg setting is "port"
    And the acfg value is "8080"
    And the acfg ServerConfig has that setting
    When the AconfigCommand action is invoked
    Then the acfg ServerConfig should have received setting "port" with integer 8080
    And the acfg player should see "New configuration:"

  # --- setting exists with non-numeric value (lines 34, 39, 41) ---------------
  Scenario: Setting a non-numeric value keeps it as string
    Given the acfg setting is "address"
    And the acfg value is "localhost"
    And the acfg ServerConfig has that setting
    When the AconfigCommand action is invoked
    Then the acfg ServerConfig should have received setting "address" with string "localhost"
    And the acfg player should see "New configuration:"

  # --- setting downcased before lookup (line 23) ------------------------------
  Scenario: Setting name is downcased before use
    Given the acfg setting is "PORT"
    And the acfg value is "9090"
    And the acfg ServerConfig has that setting
    When the AconfigCommand action is invoked
    Then the acfg ServerConfig should have received setting "port" with integer 9090
    And the acfg player should see "New configuration:"
