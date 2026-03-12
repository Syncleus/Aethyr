Feature: Aethyr custom error classes

  In order to handle domain-specific failure modes consistently
  As a developer of the Aethyr engine
  I want every custom error class in MUDError to be loadable, instantiable,
  and raisable with a descriptive message

  Scenario: Load the MUDError module
    Given I require the Aethyr error library
    Then the Aethyr error module MUDError should be defined

  Scenario: Instantiate UnknownCharacter error
    Given I require the Aethyr error library
    When I instantiate an Aethyr error "UnknownCharacter" with message "no such character"
    Then the Aethyr error should be a kind of RuntimeError
    And the Aethyr error message should be "no such character"

  Scenario: Raise and rescue UnknownCharacter error
    Given I require the Aethyr error library
    When I raise an Aethyr error "UnknownCharacter" with message "player not found"
    Then the Aethyr error should have been rescued
    And the Aethyr error class name should be "MUDError::UnknownCharacter"

  Scenario: Instantiate BadPassword error
    Given I require the Aethyr error library
    When I instantiate an Aethyr error "BadPassword" with message "wrong password"
    Then the Aethyr error should be a kind of RuntimeError
    And the Aethyr error message should be "wrong password"

  Scenario: Raise and rescue BadPassword error
    Given I require the Aethyr error library
    When I raise an Aethyr error "BadPassword" with message "invalid credentials"
    Then the Aethyr error should have been rescued
    And the Aethyr error class name should be "MUDError::BadPassword"

  Scenario: Instantiate CharacterAlreadyLoaded error
    Given I require the Aethyr error library
    When I instantiate an Aethyr error "CharacterAlreadyLoaded" with message "duplicate load"
    Then the Aethyr error should be a kind of RuntimeError
    And the Aethyr error message should be "duplicate load"

  Scenario: Raise and rescue CharacterAlreadyLoaded error
    Given I require the Aethyr error library
    When I raise an Aethyr error "CharacterAlreadyLoaded" with message "already loaded"
    Then the Aethyr error should have been rescued
    And the Aethyr error class name should be "MUDError::CharacterAlreadyLoaded"

  Scenario: Instantiate NoSuchGOID error
    Given I require the Aethyr error library
    When I instantiate an Aethyr error "NoSuchGOID" with message "missing goid"
    Then the Aethyr error should be a kind of RuntimeError
    And the Aethyr error message should be "missing goid"

  Scenario: Raise and rescue NoSuchGOID error
    Given I require the Aethyr error library
    When I raise an Aethyr error "NoSuchGOID" with message "goid not in registry"
    Then the Aethyr error should have been rescued
    And the Aethyr error class name should be "MUDError::NoSuchGOID"

  Scenario: Instantiate ObjectLoadError error
    Given I require the Aethyr error library
    When I instantiate an Aethyr error "ObjectLoadError" with message "nil object"
    Then the Aethyr error should be a kind of RuntimeError
    And the Aethyr error message should be "nil object"

  Scenario: Raise and rescue ObjectLoadError error
    Given I require the Aethyr error library
    When I raise an Aethyr error "ObjectLoadError" with message "load returned nil"
    Then the Aethyr error should have been rescued
    And the Aethyr error class name should be "MUDError::ObjectLoadError"

  Scenario: Instantiate Shutdown error
    Given I require the Aethyr error library
    When I instantiate an Aethyr error "Shutdown" with message "server shutting down"
    Then the Aethyr error should be a kind of RuntimeError
    And the Aethyr error message should be "server shutting down"

  Scenario: Raise and rescue Shutdown error
    Given I require the Aethyr error library
    When I raise an Aethyr error "Shutdown" with message "shutdown requested"
    Then the Aethyr error should have been rescued
    And the Aethyr error class name should be "MUDError::Shutdown"
