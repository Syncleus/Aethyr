Feature: Display layout selection and validation
  # This feature validates that the server correctly processes the
  # `SET LAYOUT` command for all recognised layout types as well as
  # rejecting unknown values.  The scenarios interact *exclusively*
  # via the public TCP interface of a running Aethyr instance which is
  # provisioned by the reusable `ServerHarness` utility.

  Background:
    Given the Aethyr server is running
    And I log in as the default test user

  ###################################################################
  # Valid layouts – parameterised via Scenario Outline so that Cucumber
  # generates an independent scenario for *each* supported layout.
  ###################################################################
  Scenario Outline: Selecting a valid "<layout>" display layout
    When I set layout to "<layout>"
    Then I should not receive an invalid layout error

    Examples:
      | layout  |
      | basic   |
      | partial |
      | full    |
      | wide    |

  ###############################################################
  # Invalid layout value – the server must reject unsupported    #
  # options with a clear error message to the client.            #
  ###############################################################
  Scenario: Rejecting an unsupported layout value
    When I set layout to "invalid"
    Then I should receive an invalid layout error message 