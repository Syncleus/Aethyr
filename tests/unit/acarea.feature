Feature: AcareaCommand action
  In order to let admins create new areas in the MUD
  As a maintainer of the Aethyr engine
  I want AcareaCommand#action to correctly create an area and output confirmation.

  Scenario: Creating an area with a name outputs confirmation
    Given a stubbed AcareaCommand environment
    When the AcareaCommand action is invoked with name "Forest"
    Then the acarea player should see "Created:"
