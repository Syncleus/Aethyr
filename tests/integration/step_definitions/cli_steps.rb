# frozen_string_literal: true

# =============================================================================
#  CLI Integration Test Step Definitions
# -----------------------------------------------------------------------------
#  This module encapsulates all Cucumber step definitions that interact with
#  the public `bin/aethyr` executable.  By isolating the CLI‐level concerns in
#  their own file we honour the Single-Responsibility Principle while keeping
#  the broader step-definition namespace uncluttered.  The implementation
#  leverages Aruba's rich process-orchestration API to spawn and interrogate
#  subprocesses in a platform-agnostic manner.
# =============================================================================

require 'test/unit/assertions'   # Assertion helpers (compatible with Aruba)
require 'aruba/api'              # Direct access to Aruba DSL for fine-grained control
require 'aethyr/app_info'        # Provides the authoritative VERSION constant

World(Test::Unit::Assertions)
World(Aruba::Api)                # Mixin Aruba methods into the Cucumber World


# ----------------------------------------------------------------------------
#  Step: Then the output should contain the current Aethyr version
# ----------------------------------------------------------------------------
#  Performs a dynamic assertion against the aggregated standard-output stream
#  of the most recently executed CLI command.  The step consults the canonical
#  `Aethyr::VERSION` constant so that the scenario remains stable across
#  version bumps – i.e. we do not have to hard-code the literal string in the
#  feature file, thus complying with the Open/Closed Principle.
# ----------------------------------------------------------------------------
Then('the output should contain the current Aethyr version') do
  # Aruba exposes the `last_command_started` helper which materialises the
  # Command–pattern object representing the most recently executed process.
  command = last_command_started

  # Defensive programming: ensure we *actually* have a command context. This
  # guards against nil dereferencing should the step be invoked out of order.
  assert_not_nil(command, 'No command has been executed yet – did you forget to run one?')

  # Fetch combined STDOUT+STDERR because Methadone's version banner can be
  # emitted to either depending on internal configuration.
  full_output = command.stdout + command.stderr

  # Finally, perform the assertion.  We do not care about exact placement as
  # Methadone is free to decorate the banner, hence the `include?` check.
  assert(full_output.include?(Aethyr::VERSION),
         "Expected CLI output to include version '#{Aethyr::VERSION}' but it did not.\nOutput was:\n#{full_output}")
end

# ----------------------------------------------------------------------------
#  Step: And the error output should contain {string}
# ----------------------------------------------------------------------------
#  Convenience wrapper around Aruba's stderr capture so we can write more
#  intention-revealing expectations in the feature descriptions.
# ----------------------------------------------------------------------------
And('the error output should contain {string}') do |expected|
  command = last_command_started
  assert_not_nil(command, 'No command context – was a command executed?')
  assert(command.stderr.include?(expected),
         "Expected STDERR to include '#{expected}' but it did not.\nSTDERR was:\n#{command.stderr}")
end 