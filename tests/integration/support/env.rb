# frozen_string_literal: true

# -----------------------------------------------------------------------------
#  Integration Test Environment Bootstrap
# -----------------------------------------------------------------------------
#  This file is automatically required by Cucumber for every integration run
#  (because it resides under integration/support).  The goal is to insulate the
#  integration layer from the unit-test environment whilst re-using as much of
#  the existing helper infrastructure as possible.
# -----------------------------------------------------------------------------

require 'aruba/cucumber'           # CLI/process orchestration utilities
require 'methadone/cucumber'       # Consistent CLI world helpers
require 'test/unit/assertions'     # Assertion mix-in for step definitions
require 'socket'                   # TCP client connections to the Aethyr server

require_relative '../../common_env'
