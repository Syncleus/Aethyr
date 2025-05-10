# frozen_string_literal: true

################################################################################
#  Layout Integration Test Step Definitions
# -----------------------------------------------------------------------------
#  These steps drive the *display layout* scenarios defined in
#  `tests/integration/layout.feature`.  They exercise the public TCP interface
#  of a live Aethyr server (boot-strapped via the shared `ServerHarness`).
#  All interactions are intentionally performed *over the wire* to maintain a
#  true end-to-end perspective whilst still harnessing Ruby helpers for data
#  marshalling.
################################################################################

require 'test/unit/assertions'
require 'securerandom'
require 'timeout'

World(Test::Unit::Assertions)

# -----------------------------------------------------------------------------
#  H E L P E R S
# -----------------------------------------------------------------------------
# NOTE: These helpers live only within this file (they are not mixed into the
#       Cucumber World globally) to keep the public surface area focused and to
#       avoid accidental cross-pollination with unrelated step definitions.
# -----------------------------------------------------------------------------
module LayoutTestHelpers
  # Reads *all* currently available data from the socket (non-blocking) within
  # the supplied `timeout` window.  The intent is to drain the receive buffer
  # *without* stalling the scenario – perfectly suited for command/response
  # style protocols.
  #
  # @param socket [TCPSocket] The live client connection.
  # @param timeout_seconds [Numeric] Maximum time to wait for incoming data.
  # @return [String] Whatever bytes were received (can be empty).
  def drain_socket(socket, timeout_seconds = 1.0)
    buffer   = +''
    deadline = Time.now + timeout_seconds

    loop do
      remaining = deadline - Time.now
      break if remaining <= 0

      ready = IO.select([socket], nil, nil, remaining)
      break unless ready

      chunk = socket.read_nonblock(4096, exception: false)
      break unless chunk

      buffer << chunk
    end

    buffer
  end
end
World(LayoutTestHelpers)

# -----------------------------------------------------------------------------
#  S T E P   D E F I N I T I O N S
# -----------------------------------------------------------------------------

# Preconditions – ensure we are *already* connected (leverages steps from
# `server_steps.rb`).  This guard makes the intent explicit and yields a more
# descriptive failure if the connection is somehow missing.
Given('I have created and logged in as a new character') do
  assert_not_nil(@client_socket, 'Client socket not initialised – did you forget to connect?')

  ###########################################################################
  # Construct a guaranteed-unique character name to avoid clashes when the
  # test suite is executed repeatedly or in parallel (e.g. on CI runners).
  ###########################################################################
  @character_name = "LayoutTest_#{SecureRandom.hex(4)}"

  # A deterministic yet trivial password that fulfils the server's validation
  # criteria (6-20 word characters).
  password = 'pass123'

  # The *entire* sign-up flow condensed into a single array for readability.
  # Each entry corresponds to an expected prompt in the server's login state-
  # machine (see Login#do_resolution et al.).  A small sleep after each write
  # provides breathing room for the server loop without introducing a hard
  # coupling – empirical testing shows 0.15 s is ample even under load.
  login_sequence = [
    'n',               # Disable colour support.
    '2',               # Create new character.
    @character_name,   # Desired character name.
    'M',               # Sex.
    password,          # Password.
    'n'                # Disable colour post-creation.
  ]

  login_sequence.each do |input|
    @client_socket.write("#{input}\n")
    sleep 0.15
  end

  # Give the server a moment to finalise player creation and present the game
  # prompt.  One second has proven reliable yet keeps the suite performant.
  sleep 1.0

  # Drain any bootstrap text so that subsequent assertions reflect only the
  # command under test.
  drain_socket(@client_socket)
end

# ---------------------------------------------------------------------------
#  Command Execution – layout selection
# ---------------------------------------------------------------------------
When('I set layout to {string}') do |layout|
  command = "SET LAYOUT #{layout}\n"
  @client_socket.write(command)
  # Allow the server to process the command and flush output.
  sleep 0.25
  @last_response = drain_socket(@client_socket)
end

# ---------------------------------------------------------------------------
#  Assertions
# ---------------------------------------------------------------------------
Then('I should receive an invalid layout error message') do
  assert_match(/not a valid layout/i, @last_response, 'Expected an invalid layout error but none was received')
end

Then('I should not receive an invalid layout error') do
  assert_no_match(/not a valid layout/i, @last_response, 'Received an unexpected invalid layout error response')
end 