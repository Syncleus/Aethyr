Feature: New character creation and initial login
  Verifies that a player can create a brand-new character using the public
  login dialogue and successfully reach the in-game prompt.

  Background:
    Given the Aethyr server is running

  Scenario: Creating and logging in as a new character
    When I connect as a client
    Then the connection should succeed
    And I have created and logged in as a new character
    And I disconnect 
    
  Scenario: Multiple characters connected simultaneously
    When I connect as client "client1"
    Then the connection for "client1" should succeed
    And I have created and logged in as a new character named "Character1" on connection "client1"
    When I connect as client "client2"
    Then the connection for "client2" should succeed
    And I have created and logged in as a new character named "Character2" on connection "client2"
    When I connect as client "client3"
    Then the connection for "client3" should succeed
    And I have created and logged in as a new character named "Character3" on connection "client3"
    When I switch layout to "full" for "client1"
    And I switch layout to "full" for "client2" 
    And I switch layout to "full" for "client3"
    When I type "look" on connection "client1"
    Then I should see text in "client1"
    When I type "help" on connection "client2"
    Then I should see text in "client2"
    When I type "who" on connection "client3" 
    Then I should see text in "client3"
    And I disconnect client "client1"
    And I disconnect client "client2"
    And I disconnect client "client3" 