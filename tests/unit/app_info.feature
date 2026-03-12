Feature: Application version information
  The app_info module defines the Aethyr module and its VERSION constant
  so that the engine version is available throughout the codebase.

  Scenario: Loading app_info defines the Aethyr module with a VERSION constant
    Given I require the app_info library
    Then the Aethyr module should be defined
    And the Aethyr VERSION constant should equal "1.0.0"
