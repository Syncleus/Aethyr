@cli
Feature: Aethyr command-line interface
  Verifies that the public executable `bin/aethyr` responds correctly to common
  command-line flags.  Unlike the rest of the integration suite this feature
  interacts *exclusively* with the CLI process – it does **not** spin up an
  Aethyr game server via the `ServerHarness` utilities.  This design decision
  ensures a clear separation of concerns between binary-level smoke tests and
  full-stack network integration scenarios.

  Scenario: Displaying the built-in help banner
    When I run `bash -c "cd /app && bundle exec bin/aethyr --help"`
    Then the exit status should be 0
    And the output should contain "The Aethyr MUD server."

  Scenario: Displaying the version banner
    When I run `bash -c "cd /app && bundle exec bin/aethyr --version"`
    Then the exit status should be 0
    And the output should contain the current Aethyr version

  Scenario: Rejecting unknown command-line flags
    When I run `bash -c "cd /app && bundle exec bin/aethyr --definitely-invalid-flag"`
    Then the exit status should not be 0
    And the output should contain "Usage:"

  Scenario: Displaying the intro banner over a TCP connection
    Given I start the Aethyr server on a random port
    When I establish a raw TCP connection to the server
    Then I should receive the intro banner 