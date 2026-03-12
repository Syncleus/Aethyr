Feature: Aethyr::Experiments::Sandbox
  The Sandbox class acts as a facade and execution context for user scripts,
  exposing a pleasant DSL while hiding the complexity of the underlying server.

  Scenario: Creating a Sandbox instance
    Given I have a mock server and player for the sandbox
    When I create a new Sandbox with verbose false
    Then the sandbox should be an instance of Aethyr::Experiments::Sandbox
    And the sandbox player should be the mock player

  Scenario: Creating a verbose Sandbox instance
    Given I have a mock server and player for the sandbox
    When I create a new Sandbox with verbose true
    Then the sandbox should be an instance of Aethyr::Experiments::Sandbox

  Scenario: Accessing the player
    Given I have a sandbox instance
    Then the sandbox player method should return the player

  Scenario: Enqueuing a command with default timing
    Given I have a sandbox instance
    When I enqueue sandbox command "look around"
    Then the sandbox command queue should contain 1 entry
    And the sandbox command queue entry should have cmd "look around"

  Scenario: Enqueuing a command with a future eta
    Given I have a sandbox instance
    When I enqueue sandbox command "say hello" at 5 seconds
    Then the sandbox command queue should contain 1 entry

  Scenario: Dispatching due commands
    Given I have a sandbox instance with CommandParser defined
    When I enqueue sandbox command "look" with past eta
    And I dispatch queued sandbox commands
    Then the sandbox command queue should be empty
    And the mock player should have received an alert

  Scenario: Dispatching commands when none are due
    Given I have a sandbox instance with CommandParser defined
    When I enqueue sandbox command "say hello" at 9999 seconds
    And I dispatch queued sandbox commands
    Then the sandbox command queue should contain 1 entry

  Scenario: Command execution handles parser returning nil
    Given I have a sandbox instance with CommandParser returning nil
    When I enqueue sandbox command "emote waves" with past eta
    And I dispatch queued sandbox commands
    Then the sandbox command queue should be empty
    And the mock player should not have received an alert

  Scenario: Command execution handles errors gracefully
    Given I have a sandbox instance with CommandParser raising an error
    When I enqueue sandbox command "broken" with past eta
    And I dispatch queued sandbox commands
    Then the sandbox command queue should be empty

  Scenario: Scheduling a recurring task via every
    Given I have a sandbox instance
    When I schedule a recurring sandbox task every 2 seconds
    Then no error should be raised by the sandbox

  Scenario: Every raises ArgumentError for non-positive interval
    Given I have a sandbox instance
    When I schedule a recurring sandbox task every 0 seconds
    Then an ArgumentError should be raised by the sandbox with message "Interval must be positive"

  Scenario: Recurring task error handling
    Given I have a verbose sandbox instance
    When I schedule a recurring sandbox task that raises an error
    And I execute the recurring sandbox task block
    Then no error should be raised by the sandbox

  Scenario: Wait until idle with empty queue
    Given I have a sandbox instance
    When I wait until the sandbox is idle
    Then no error should be raised by the sandbox

  Scenario: Logging when verbose is false
    Given I have a sandbox instance with verbose false
    When I call sandbox log with message "test message"
    Then the sandbox log should not have called super

  Scenario: Logging when verbose is true
    Given I have a verbose sandbox instance
    When I call sandbox log with message "verbose message"
    Then the sandbox log should have called super

  Scenario: Executing the internal scheduler block
    Given I have a sandbox instance
    When I execute the sandbox scheduler block
    Then no error should be raised by the sandbox

  Scenario: Verbose command execution error logs the failure
    Given I have a verbose sandbox instance with CommandParser raising an error
    When I enqueue sandbox command "broken" with past eta
    And I dispatch queued sandbox commands
    Then the sandbox command queue should be empty
    And the sandbox log should have recorded a failure message

  Scenario: Recurring task block invokes user block successfully
    Given I have a verbose sandbox instance
    When I schedule a recurring sandbox task that succeeds
    And I execute the recurring sandbox task block
    Then the sandbox recurring block should have been called

  Scenario: Recurring task block catches errors from user block
    Given I have a verbose sandbox instance
    When I schedule a recurring sandbox task that raises an error
    And I execute the recurring sandbox task block
    Then the sandbox log should have recorded a recurring error
