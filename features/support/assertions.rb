# frozen_string_literal: true
#
# -------------------------------------------------------------------
#  Custom Cucumber assertion helpers
# -------------------------------------------------------------------
#  This file is required automatically by Cucumber (because it lives
#  in features/support).  It extends the World with
#  +assert_raises_with_message+, a convenience wrapper around
#  Test::Unit's +assert_raises+ that also checks the exception's
#  message (string-equality or regex-match).
#
require 'test/unit/assertions'

module CustomAssertions
  include Test::Unit::Assertions

  # Assert that +block+ raises +expected_exception+ whose message
  # matches +expected_message+.
  #
  # @param expected_exception [Class<Exception>]
  # @param expected_message [String, Regexp]
  # @yield [] the code expected to raise
  # @return [Exception] the captured exception (allows further checks)
  def assert_raises_with_message(expected_exception, expected_message, &block)
    raised = assert_raises(expected_exception, &block)

    case expected_message
    when Regexp   then assert_match(expected_message, raised.message)
    else               assert_equal(expected_message.to_s, raised.message)
    end

    raised
  end
end

World(CustomAssertions) 