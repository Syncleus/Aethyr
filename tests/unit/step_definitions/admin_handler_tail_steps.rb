# features/step_definitions/admin_handler_tail_steps.rb
# frozen_string_literal: true
################################################################################
# Steps for exercising the protected `AdminHandler#tail` method.               #
#                                                                              #
# These scenarios target lines 22, 24-26, and 29 of                            #
#   lib/aethyr/core/input_handlers/admin/admin_handler.rb                      #
# which implement the file-tailing utility used by admin commands.             #
################################################################################

require 'test/unit/assertions'
require 'tempfile'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World – scenario-specific state for the tail tests                           #
###############################################################################
module AdminHandlerTailWorld
  # @!attribute [rw] tail_handler
  #   @return [Object] AdminHandler subclass instance exposing #tail
  # @!attribute [rw] tail_tempfile
  #   @return [Tempfile] temporary file used as the tail target
  # @!attribute [rw] tail_result
  #   @return [Array] return value from #tail
  attr_accessor :tail_handler, :tail_tempfile, :tail_result
end
World(AdminHandlerTailWorld)

###############################################################################
# Concrete subclass that exposes the protected `tail` method for testing.      #
# We define it once and reuse across all scenarios.                            #
###############################################################################
unless defined?(TailTestHandler)
  # Ensure the load path includes the directory that lets
  # `require 'util/tail'` (issued inside AdminHandler#tail) resolve to
  # lib/aethyr/core/util/tail.rb.
  core_lib = File.expand_path('../../../lib/aethyr/core', __dir__)
  $LOAD_PATH.unshift(core_lib) unless $LOAD_PATH.include?(core_lib)

  require 'aethyr/core/input_handlers/admin/admin_handler'

  # Minimal concrete subclass whose sole purpose is to make the protected
  # `#tail` method callable from the test harness.
  class TailTestHandler < Aethyr::Extend::AdminHandler
    def initialize(player)
      super(player, [])
    end

    # Re-expose the protected method as public so step definitions can
    # invoke it directly.
    public :tail
  end
end

###############################################################################
# Given-steps                                                                  #
###############################################################################
Given('the tail test harness is ready') do
  player = ::Aethyr::Core::Objects::MockPlayer.new
  player.admin = true

  # Provide a minimal $manager so that handler initialisation does not fail.
  unless $manager.respond_to?(:submit_action)
    $manager = Struct.new(:actions) do
      def submit_action(a); actions << a; end
    end.new([])
  end

  self.tail_handler = TailTestHandler.new(player)
end

Given('a temporary file with {int} lines of content') do |line_count|
  self.tail_tempfile = Tempfile.new(['admin_tail_test', '.log'])
  line_count.times do |i|
    tail_tempfile.puts "log line #{i + 1}"
  end
  tail_tempfile.flush
  tail_tempfile.close
end

###############################################################################
# When-steps                                                                   #
###############################################################################
When('the admin handler tails the file with default arguments') do
  self.tail_result = tail_handler.tail(tail_tempfile.path)
end

When('the admin handler tails the file requesting {int} lines') do |count|
  self.tail_result = tail_handler.tail(tail_tempfile.path, count)
end

###############################################################################
# Then-steps                                                                   #
###############################################################################
Then('the tail output should contain {int} content lines') do |expected|
  # The last element is always the summary line, so content lines are all but
  # the last entry.
  content_lines = tail_result[0..-2]
  assert_equal(expected, content_lines.length,
               "Expected #{expected} content line(s) but got #{content_lines.length}: #{content_lines.inspect}")
end

Then('the tail output should end with a lines-shown summary') do
  last = tail_result.last
  assert_match(/\A\(\d+ lines shown\.\)\z/, last,
               "Expected last element to be a summary like '(N lines shown.)' but got: #{last.inspect}")
end

###############################################################################
# Cleanup – remove temporary files after each scenario                         #
###############################################################################
After do
  if defined?(tail_tempfile) && tail_tempfile.respond_to?(:unlink)
    tail_tempfile.unlink rescue nil
  end
end
