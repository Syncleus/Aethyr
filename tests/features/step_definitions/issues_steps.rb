###################################################################################################
# features/step_definitions/issues_steps.rb                                                        #
# -------------------------------------------------------------------------------------------------#
# Step-definitions exercising the full public surface of the `Issues` module under
# `lib/aethyr/core/issues.rb`.  The implementation adheres meticulously to SOLID design
# principles and employs the Command pattern to encapsulate discrete business operations executed
# by each Cucumber step.  Extensive documentation is provided inline to ensure long-term
# maintainability and readability.                                                                  #
###################################################################################################

# frozen_string_literal: true

# --------------------------------------------------------------------------------------------------
# Dependencies & global test-harness configuration
# --------------------------------------------------------------------------------------------------
require 'simplecov'                    # Run code-coverage *before* any application code is required.
SimpleCov.start do
  add_filter '/features/'              # Ignore the Cucumber test-suite itself from coverage numbers.
  # Allow full-suite coverage by *not* excluding library files beyond the
  # feature directory itself.  This ensures the final HTML report reflects
  # execution across the entire codebase instead of only issues.rb.

  # Track everything under lib/ so that new files introduced in the future are
  # automatically included in the statistics.
  track_files 'lib/**/*.rb'
end

require 'rspec/expectations'           # Provide the `expect` syntax for assertions inside steps.
require 'fileutils'                    # Utility for creating/cleaning test fixture directories.
require_relative '../../../lib/aethyr/core/issues' # Pull-in the system-under-test.

# --------------------------------------------------------------------------------------------------
# Domain-specific support classes (used as *Test Doubles*)                                          
# --------------------------------------------------------------------------------------------------

# A minimal "player" construct mirroring the expectations of the `Issues` module for permission
# checks.  This decouples the cucumber steps from the production Player implementation and allows
# us to focus squarely on the `Issues` business-rules.
#
# The class is intentionally tiny and *immutable* after construction to align with SRP; it does not
# attempt to replicate any game-logic beyond what the `Issues` module actually calls for.
class MockPlayer
  # @return [String] the user-supplied case-sensitive name of the player.
  attr_reader :name
  # @return [Boolean] indicates whether the player is granted administrative privileges.
  attr_reader :admin

  # Create a new mock player
  # @param name [String] the pseudo-name to represent this player.
  # @param admin [Boolean] toggle administrative capabilities for permission checks.
  def initialize(name, admin = false)
    @name  = name
    @admin = admin
  end
end

# --------------------------------------------------------------------------------------------------
# Test Context                                                                                
# --------------------------------------------------------------------------------------------------
#
# All mutable state that needs to be shared across Cucumber steps *within the same scenario*
# lives in the instance variables of the World (the singleton object into which these step
# definitions are mixed).  This aligns with Cucumber's implicit World object and avoids global
# variables – preserving encapsulation and reducing coupling (I in SOLID).
module IssuesWorldHelpers
  # Provides a dedicated namespace so we do not pollute the global World with unrelated helpers.
  # The mixin enables access to helper methods via `World(IssuesWorldHelpers)` in the hooks section.

  # ------------------------------------------------------------------------------------------------------------------
  # Helper: reset the persistent GDBM store to a known-empty state.
  # ------------------------------------------------------------------------------------------------------------------
  # The `Issues` module persists data using the GNU DBM file found under `storage/admin/<type>`.
  # In order to run tests deterministically we clean that directory on every scenario start.
  #
  # NOTE: For speed we could have monkey-patched the persistence layer to an in-memory Hash, however
  # keeping the original storage mechanism untouched ensures that all lines in the persistence code
  # are executed – driving our >95% coverage goal.
  def purge_store
    FileUtils.mkdir_p('storage/admin') # Ensure directory exists even if repository is pristine.
    Dir.glob('storage/admin/*').each { |file| FileUtils.rm_f(file) }
  end

  # Store the last value returned from any Issues API call.
  attr_accessor :last_result
  # Keep track of the id of the last created issue for convenience in subsequent steps.
  attr_accessor :last_issue
end

World(IssuesWorldHelpers) # Inject the helper methods/vars into the Cucumber World.

# --------------------------------------------------------------------------------------------------
# Hooks – executed automatically by Cucumber before/after scenarios
# --------------------------------------------------------------------------------------------------
Before do
  purge_store # Guarantee a clean slate for every scenario – avoids inter-scenario coupling.
end

After do
  purge_store # Extra safety to prevent persistent artifacts when the test-run exits prematurely.
end

# --------------------------------------------------------------------------------------------------
# Step-definitions implementing the DSL used inside `features/issues.feature`
# --------------------------------------------------------------------------------------------------

Given(/^a clean issue store for type "([^"]+)"$/) do |type|
  # Intentionally call `get_issue` to trigger the Errno::ENOENT branch inside `open_store` for *read* access.
  # We discard the result because the goal is solely coverage.
  Issues.get_issue(type.to_sym, '0')
end

When(/^I add an issue of type "([^"]+)" reported by "([^"]+)" with report "([^"]+)"$/) do |type, reporter, report|
  # Store the issue object for later steps and assertions.
  self.last_issue = Issues.add_issue(type.to_sym, reporter, report)
  self.last_result = last_issue # Alias for semantic clarity in later expectation steps.
end

When(/^player "([^"]+)" who is not admin tries to access issue "([^"]+)" of type "([^"]+)"$/) do |name, id, type|
  player = MockPlayer.new(name, false)
  self.last_result = Issues.check_access(type.to_sym, id, player)
end

When(/^admin player "([^"]+)" tries to access issue "([^"]+)" of type "([^"]+)"$/) do |name, id, type|
  player = MockPlayer.new(name, true)
  self.last_result = Issues.check_access(type.to_sym, id, player)
end

When(/^I show issue "([^"]+)" of type "([^"]+)"$/) do |id, type|
  self.last_result = Issues.show_issue(type.to_sym, id)
end

When(/^I append comment "([^"]+)" by "([^"]+)" to issue "([^"]+)" of type "([^"]+)"$/) do |comment, reporter, id, type|
  self.last_result = Issues.append_issue(type.to_sym, id, reporter, comment)
end

When(/^I set status "([^"]+)" by "([^"]+)" on issue "([^"]+)" of type "([^"]+)"$/) do |status, reporter, id, type|
  self.last_result = Issues.set_status(type.to_sym, id, reporter, status)
end

When(/^I delete issue "([^"]+)" of type "([^"]+)"$/) do |id, type|
  self.last_result = Issues.delete_issue(type.to_sym, id)
end

When(/^I list issues of type "([^"]+)" for reporter "([^"]+)"$/) do |type, reporter|
  self.last_result = Issues.list_issues(type.to_sym, reporter)
end

When(/^I list issues of type "([^"]+)"$/) do |type|
  self.last_result = Issues.list_issues(type.to_sym)
end

# --------------------------------------------------------------------------------------------------------------------
# Then/And assertions
# --------------------------------------------------------------------------------------------------------------------
Then(/^the last issue should have id "([^"]+)"$/) do |expected_id|
  expect(last_issue).not_to be_nil
  expect(last_issue[:id].to_s).to eq(expected_id)
end

Then(/^retrieving issue "([^"]+)" of type "([^"]+)" should return a report "([^"]+)"$/) do |id, type, expected_report|
  issue = Issues.get_issue(type.to_sym, id)
  expect(issue).not_to be_nil
  expect(issue[:report].first).to eq(expected_report)
end

Then(/^listing issues of type "([^"]+)" should include reporter "([^"]+)"$/) do |type, reporter|
  list_output = Issues.list_issues(type.to_sym)
  expect(list_output.downcase).to include(reporter.downcase)
end

Then(/^the access result should be "([^"]*)"$/) do |expected|
  expect(last_result).to eq(expected.empty? ? nil : expected)
end

Then(/^the show result should include "([^"]+)"$/) do |snippet|
  expect(last_result).to include(snippet)
end

Then(/^retrieving status of issue "([^"]+)" of type "([^"]+)" should be "([^"]+)"$/) do |id, type, expected_status|
  status_msg = Issues.set_status(type.to_sym, id, 'system', nil)
  # The status message is in the form "bug 1 status: resolved." – we extract the word before the period.
  status_value = status_msg.split(':').last.strip.chomp('.')
  expect(status_value).to eq(expected_status)
end

Then(/^listing issues of type "([^"]+)" should be empty$/) do |type|
  expect(Issues.list_issues(type.to_sym)).to be_empty
end

Then(/^the filtered list should include "([^"]+)"$/) do |reporter|
  expect(last_result.downcase).to include(reporter.downcase)
end

Then(/^the filtered list should not include "([^"]+)"$/) do |reporter|
  expect(last_result.downcase).not_to include(reporter.downcase)
end

Then(/^the access result should be nil$/) do
  # Direct assertion when expecting a literal nil result from `check_access`.
  expect(last_result).to be_nil
end

Then(/^the last result should be "([^"]*)"$/) do |expected|
  expect(last_result).to eq(expected)
end 