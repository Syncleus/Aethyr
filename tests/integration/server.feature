Feature: Aethyr server integration testing
  Background:
    Given the Aethyr server is running

  Scenario: Single-client connectivity
    When I connect as a client
    Then the connection should succeed
    And I disconnect

  Scenario: Multi-client connectivity
    When I connect 3 clients
    Then all clients should remain connected
    And I disconnect all clients 