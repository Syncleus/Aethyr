Feature: AsetHandler input parsing
  In order to ensure the AsetHandler correctly routes admin input to AsetCommand
  As a maintainer of the Aethyr engine
  I want the AsetHandler player_input method to parse aset and aset! commands.

  Background:
    Given a stubbed AsetHandler input environment

  Scenario: aset with an @-prefixed attribute submits an AsetCommand
    When the admin handler input is "aset sword @name Excalibur"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have object "sword"
    And the submitted aset action should have attribute "@name"
    And the submitted aset action should have value "Excalibur"
    And the submitted aset action should not have force

  Scenario: aset with a named smell attribute submits an AsetCommand
    When the admin handler input is "aset chest smell musty old wood"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have object "chest"
    And the submitted aset action should have attribute "smell"
    And the submitted aset action should have value "musty old wood"

  Scenario: aset with a named feel attribute submits an AsetCommand
    When the admin handler input is "aset table feel rough"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have attribute "feel"

  Scenario: aset with a named texture attribute submits an AsetCommand
    When the admin handler input is "aset wall texture grainy"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have attribute "texture"

  Scenario: aset with a named taste attribute submits an AsetCommand
    When the admin handler input is "aset potion taste bitter"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have attribute "taste"

  Scenario: aset with a named sound attribute submits an AsetCommand
    When the admin handler input is "aset bell sound ringing"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have attribute "sound"

  Scenario: aset with a named listen attribute submits an AsetCommand
    When the admin handler input is "aset river listen bubbling"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have attribute "listen"

  Scenario: aset with multi-word object name
    When the admin handler input is "aset old rusty sword @desc a legendary blade"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have object "old rusty sword"
    And the submitted aset action should have attribute "@desc"
    And the submitted aset action should have value "a legendary blade"

  Scenario: aset! with an @-prefixed attribute submits a forced AsetCommand
    When the admin handler input is "aset! gem @color ruby red"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have object "gem"
    And the submitted aset action should have attribute "@color"
    And the submitted aset action should have value "ruby red"
    And the submitted aset action should have force

  Scenario: aset! with a named smell attribute submits a forced AsetCommand
    When the admin handler input is "aset! flower smell sweet"
    Then the aset handler should have submitted 1 action
    And the submitted aset action should have attribute "smell"
    And the submitted aset action should have force

  Scenario: Non-matching input does not submit any action
    When the admin handler input is "look around"
    Then the aset handler should have submitted 0 actions
