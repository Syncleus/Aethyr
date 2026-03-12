Feature: Aethyr::Experiments::CLI argument parsing
  The CLI class is a thin façade over OptionParser that translates
  command-line tokens into an OpenStruct consumed by Runner.

  Scenario: Successful invocation with only a script path uses defaults
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "my_script.rb"
    Then the CLI Runner should have been called
    And the CLI parsed option "script" should be "my_script.rb"
    And the CLI parsed option "player" should be "TestSubject"
    And the CLI parsed option "attach" should be false
    And the CLI parsed option "verbose" should be false

  Scenario: Custom player name via short flag
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "-p Alice my_script.rb"
    Then the CLI Runner should have been called
    And the CLI parsed option "player" should be "Alice"
    And the CLI parsed option "script" should be "my_script.rb"

  Scenario: Custom player name via long flag
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "--player Bob my_script.rb"
    Then the CLI Runner should have been called
    And the CLI parsed option "player" should be "Bob"

  Scenario: Attach flag via short flag
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "-a my_script.rb"
    Then the CLI Runner should have been called
    And the CLI parsed option "attach" should be true

  Scenario: Attach flag via long flag
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "--attach my_script.rb"
    Then the CLI Runner should have been called
    And the CLI parsed option "attach" should be true

  Scenario: Verbose flag via short flag
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "-v my_script.rb"
    Then the CLI Runner should have been called
    And the CLI parsed option "verbose" should be true

  Scenario: No-verbose flag disables verbosity
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "--no-verbose my_script.rb"
    Then the CLI Runner should have been called
    And the CLI parsed option "verbose" should be false

  Scenario: Help flag prints usage and exits
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "-h"
    Then the CLI should have exited with status 0
    And the CLI stdout should contain "Usage:"

  Scenario: Missing script path prints error and exits with status 1
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments ""
    Then the CLI should have exited with status 1
    And the CLI stderr should contain "ERROR: Please supply a Ruby experiment script"

  Scenario: Invalid option prints error and exits with status 1
    Given the CLI module is loaded with a stubbed Runner
    When I call CLI.start with arguments "--bogus my_script.rb"
    Then the CLI should have exited with status 1
    And the CLI stderr should contain "invalid option: --bogus"
