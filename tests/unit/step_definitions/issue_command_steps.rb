# frozen_string_literal: true
###############################################################################
# Step definitions for IssueCommand action coverage.                          #
#                                                                             #
# These steps exercise every branch of                                        #
# lib/aethyr/core/actions/commands/issue.rb to achieve >97% line coverage.    #
#                                                                             #
# The Issues module is stubbed to avoid GDBM persistence issues in the test   #
# environment. This isolates the command logic under test.                     #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/issue'
require 'aethyr/core/issues'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module IssueCommandWorld
  attr_accessor :issue_player, :issue_command,
                :stub_check_access_result,
                :stub_add_issue_result,
                :stub_append_issue_result,
                :stub_delete_issue_result,
                :stub_list_issues_result,
                :stub_show_issue_result,
                :stub_set_status_result
end
World(IssueCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# A minimal player double that records output messages and exposes admin flag.
class IssueCmdTestPlayer
  attr_accessor :admin
  attr_reader :messages

  def initialize(admin = false)
    @admin    = admin
    @messages = []
  end

  # Return a mutable string to avoid FrozenError in Issues.list_issues
  def name
    String.new('Testplayer')
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed IssueCommand environment') do
  @issue_player = IssueCmdTestPlayer.new(false)

  # Default stub results
  @stub_add_issue_result    = { id: '1' }
  @stub_check_access_result = nil          # nil = access granted
  @stub_append_issue_result = 'Added your comment to bug 1.'
  @stub_delete_issue_result = 'Deleted bug #1.'
  @stub_list_issues_result  = 'bug#1 (new) Testplayer 2026-03-12: Sample issue report'
  @stub_show_issue_result   = "Reported by Testplayer on 2026-03-12. Status: new"
  @stub_set_status_result   = 'Set status of bug 1 to resolved.'

  # Save original Issues methods so we can restore them after
  @original_issues_methods = {}
  %i[add_issue check_access append_issue delete_issue list_issues show_issue set_status].each do |m|
    @original_issues_methods[m] = Issues.method(m) if Issues.respond_to?(m)
  end

  # Capture references for closures
  world = self

  # Stub Issues module methods
  Issues.define_singleton_method(:add_issue) do |_type, _reporter, _report|
    world.stub_add_issue_result
  end

  Issues.define_singleton_method(:check_access) do |_type, _id, _player|
    world.stub_check_access_result
  end

  Issues.define_singleton_method(:append_issue) do |_type, _id, _reporter, _report|
    world.stub_append_issue_result
  end

  Issues.define_singleton_method(:delete_issue) do |_type, _id|
    world.stub_delete_issue_result
  end

  Issues.define_singleton_method(:list_issues) do |_type, _reporter = nil|
    world.stub_list_issues_result
  end

  Issues.define_singleton_method(:show_issue) do |_type, _id|
    world.stub_show_issue_result
  end

  Issues.define_singleton_method(:set_status) do |_type, _id, _reporter, _status|
    world.stub_set_status_result
  end
end

Given('issue access will be denied with {string}') do |message|
  @stub_check_access_result = message
end

Given('issue access will be granted') do
  @stub_check_access_result = nil
end

Given('the issue player is admin') do
  @issue_player.admin = true
end

Given('the issue list is empty') do
  @stub_list_issues_result = ''
end

###############################################################################
# Hooks – restore Issues module after each scenario                           #
###############################################################################
After do
  if @original_issues_methods
    @original_issues_methods.each do |method_name, original_method|
      Issues.define_singleton_method(method_name, original_method)
    end
    @original_issues_methods = nil
  end
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('the issue command is invoked with option {string} itype {string} and value {string}') do |option, itype, value|
  @issue_command = Aethyr::Core::Actions::Issue::IssueCommand.new(
    @issue_player,
    player: @issue_player,
    option: option,
    itype: itype.to_sym,
    value: value
  )
  @issue_command.action
end

When('the issue command is invoked with option {string} itype {string} and no issue_id') do |option, itype|
  @issue_command = Aethyr::Core::Actions::Issue::IssueCommand.new(
    @issue_player,
    player: @issue_player,
    option: option,
    itype: itype.to_sym,
    issue_id: nil,
    value: nil
  )
  @issue_command.action
end

When('the issue command is invoked with option {string} itype {string} issue_id {string} and value {string}') do |option, itype, issue_id, value|
  @issue_command = Aethyr::Core::Actions::Issue::IssueCommand.new(
    @issue_player,
    player: @issue_player,
    option: option,
    itype: itype.to_sym,
    issue_id: issue_id,
    value: value.empty? ? nil : value
  )
  @issue_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the issue player should see {string}') do |expected|
  assert(
    @issue_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{@issue_player.messages.inspect}"
  )
end
