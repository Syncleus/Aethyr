@unit
Feature: Experiment Runner orchestration
  As a developer of the Aethyr experiments subsystem
  I want the Aethyr::Experiments::Runner to correctly validate, boot,
  bootstrap players, execute scripts, and shut down
  So that experiments run reliably in a hermetic sandbox

  # ---------------------------------------------------------------------------
  #  Module & class loading
  # ---------------------------------------------------------------------------
  Scenario: Loading the Runner module defines the expected constants
    Given the Runner module is loaded
    Then the class Aethyr::Experiments::Runner should be defined

  # ---------------------------------------------------------------------------
  #  Construction
  # ---------------------------------------------------------------------------
  Scenario: Constructing a Runner stores the options struct
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose false
    When I construct a Runner with those options
    Then the Runner should be an instance of Aethyr::Experiments::Runner

  # ---------------------------------------------------------------------------
  #  Delegated predicates
  # ---------------------------------------------------------------------------
  Scenario: Runner delegates verbose? to options
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose true
    When I construct a Runner with those options
    Then the Runner verbose? should be true

  Scenario: Runner delegates attach? to options
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach true and verbose false
    When I construct a Runner with those options
    Then the Runner attach? should be true

  # ---------------------------------------------------------------------------
  #  validate_script_path! – valid file
  # ---------------------------------------------------------------------------
  Scenario: validate_script_path! passes when script file exists
    Given the Runner module is loaded
    And a Runner options struct with a valid temp script
    When I construct a Runner with those options
    And I call validate_script_path! on the Runner
    Then no error should have been raised by the Runner

  # ---------------------------------------------------------------------------
  #  validate_script_path! – missing file
  # ---------------------------------------------------------------------------
  Scenario: validate_script_path! aborts when script file is missing
    Given the Runner module is loaded
    And a Runner options struct with script "/nonexistent/bogus.rb" and player "sandbox" and attach false and verbose false
    When I construct a Runner with those options
    And I call validate_script_path! on the Runner expecting abort
    Then the Runner should have aborted with message containing "does not exist"

  # ---------------------------------------------------------------------------
  #  boot_or_attach_server – attach mode with $manager present
  # ---------------------------------------------------------------------------
  Scenario: boot_or_attach_server attaches when $manager is present
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach true and verbose true
    When I construct a Runner with those options
    And $manager is set to a fake manager for Runner tests
    And I call boot_or_attach_server on the Runner
    Then no error should have been raised by the Runner

  # ---------------------------------------------------------------------------
  #  boot_or_attach_server – attach mode with $manager nil
  # ---------------------------------------------------------------------------
  Scenario: boot_or_attach_server aborts when $manager is nil in attach mode
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach true and verbose false
    When I construct a Runner with those options
    And $manager is cleared for Runner tests
    And I call boot_or_attach_server on the Runner expecting abort
    Then the Runner should have aborted with message containing "no active server"

  # ---------------------------------------------------------------------------
  #  boot_or_attach_server – spawn mode via boot_or_attach_server
  # ---------------------------------------------------------------------------
  Scenario: boot_or_attach_server calls spawn when attach is false
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose true
    When I construct a Runner with those options
    And I call boot_or_attach_server in non-attach mode on the Runner
    Then no error should have been raised by the Runner

  # ---------------------------------------------------------------------------
  #  boot_or_attach_server – spawn mode with executable launcher
  # ---------------------------------------------------------------------------
  Scenario: spawn_ephemeral_server spawns server when launcher is executable
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose true
    When I construct a Runner with those options
    And spawn is stubbed to return a fake pid for Runner tests
    And $manager is set to a fake manager for Runner tests
    And I call spawn_ephemeral_server on the Runner with executable launcher
    Then the Runner should have a spawned pid

  # ---------------------------------------------------------------------------
  #  boot_or_attach_server – spawn mode with non-executable launcher (fallback)
  # ---------------------------------------------------------------------------
  Scenario: spawn_ephemeral_server falls back to minimal core boot
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose true
    When I construct a Runner with those options
    And I call spawn_ephemeral_server on the Runner with non-executable launcher
    Then $manager should be set for Runner tests

  # ---------------------------------------------------------------------------
  #  spawn_ephemeral_server – Timeout::Error
  # ---------------------------------------------------------------------------
  Scenario: spawn_ephemeral_server aborts on timeout
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose false
    When I construct a Runner with those options
    And I call spawn_ephemeral_server on the Runner expecting timeout abort
    Then the Runner should have aborted with message containing "timed-out"

  # ---------------------------------------------------------------------------
  #  bootstrap_player – existing player
  # ---------------------------------------------------------------------------
  Scenario: bootstrap_player loads an existing player
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose true
    When I construct a Runner with those options
    And $manager is set to a fake manager that has the player for Runner tests
    And I call bootstrap_player on the Runner
    Then the Runner should have a sandbox with the loaded player

  # ---------------------------------------------------------------------------
  #  bootstrap_player – new player
  # ---------------------------------------------------------------------------
  Scenario: bootstrap_player creates a new player when not existing
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "newsandbox" and attach false and verbose true
    When I construct a Runner with those options
    And $manager is set to a fake manager without the player for Runner tests
    And I call bootstrap_player on the Runner
    Then the Runner should have a sandbox with the created player

  # ---------------------------------------------------------------------------
  #  run_experiment_script
  # ---------------------------------------------------------------------------
  Scenario: run_experiment_script evaluates the script in the sandbox
    Given the Runner module is loaded
    And a Runner with a fake sandbox and valid script
    When I call run_experiment_script on the Runner
    Then the Runner sandbox should have evaluated the script

  # ---------------------------------------------------------------------------
  #  graceful_shutdown – without spawned pid
  # ---------------------------------------------------------------------------
  Scenario: graceful_shutdown exits cleanly without a spawned pid
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose false
    When I construct a Runner with those options
    And I call graceful_shutdown on the Runner with exit stubbed
    Then the Runner should have exited with status 0

  # ---------------------------------------------------------------------------
  #  graceful_shutdown – with spawned pid
  # ---------------------------------------------------------------------------
  Scenario: graceful_shutdown kills spawned server and exits
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose false
    When I construct a Runner with those options
    And the Runner has a spawned pid
    And I call graceful_shutdown on the Runner with exit stubbed
    Then the Runner should have killed the spawned process
    And the Runner should have exited with status 0

  # ---------------------------------------------------------------------------
  #  graceful_shutdown – non-zero exit
  # ---------------------------------------------------------------------------
  Scenario: graceful_shutdown exits with non-zero status
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose false
    When I construct a Runner with those options
    And I call graceful_shutdown on the Runner with exit stubbed and status 1
    Then the Runner should have exited with status 1

  # ---------------------------------------------------------------------------
  #  log – verbose mode
  # ---------------------------------------------------------------------------
  Scenario: log outputs when verbose is true
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose true
    When I construct a Runner with those options
    And I call log on the Runner with message "hello"
    Then the Runner log should have been invoked

  # ---------------------------------------------------------------------------
  #  log – non-verbose mode
  # ---------------------------------------------------------------------------
  Scenario: log suppresses output when verbose is false
    Given the Runner module is loaded
    And a Runner options struct with script "test.rb" and player "sandbox" and attach false and verbose false
    When I construct a Runner with those options
    And I call log on the Runner with message "hello"
    Then the Runner log should not have been invoked

  # ---------------------------------------------------------------------------
  #  execute – happy path
  # ---------------------------------------------------------------------------
  Scenario: execute runs the full template method successfully
    Given the Runner module is loaded
    And a fully stubbed Runner for the happy path
    When I call execute on the Runner
    Then the Runner should have completed execution successfully

  # ---------------------------------------------------------------------------
  #  execute – Interrupt rescue
  # ---------------------------------------------------------------------------
  Scenario: execute rescues Interrupt and shuts down
    Given the Runner module is loaded
    And a fully stubbed Runner that raises Interrupt during validation
    When I call execute on the Runner
    Then the Runner should have shut down after interrupt

  # ---------------------------------------------------------------------------
  #  execute – StandardError rescue
  # ---------------------------------------------------------------------------
  Scenario: execute rescues StandardError and shuts down with non-zero status
    Given the Runner module is loaded
    And a fully stubbed Runner that raises StandardError during validation
    When I call execute on the Runner
    Then the Runner should have shut down after standard error
