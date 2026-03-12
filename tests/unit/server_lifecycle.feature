@unit
Feature: Server lifecycle and connection management
  As a game engine developer
  I want the Aethyr::Server to correctly initialise, accept connections,
  manage players, and clean up resources
  So the MUD engine operates reliably under all conditions

  # ---------------------------------------------------------------------------
  #  Loading the Server module and exercising top-level declarations
  # ---------------------------------------------------------------------------
  Scenario: Loading the Server module sets global constants
    Given the Server module is loaded
    Then the game server AETHYR_VERSION should be "1.0.0"
    And the game server LOAD_PATH should include the connection directory

  # ---------------------------------------------------------------------------
  #  ClientConnectionResetError
  # ---------------------------------------------------------------------------
  Scenario: ClientConnectionResetError with default arguments
    Given the Server module is loaded
    When I create a Server ClientConnectionResetError with defaults
    Then the Server error message should be "Client connection reset"
    And the Server error addrinfo should be nil
    And the Server error original_error should be nil

  Scenario: ClientConnectionResetError with custom arguments
    Given the Server module is loaded
    When I create a Server ClientConnectionResetError with message "socket died" and addrinfo "127.0.0.1" and original error "ECONNRESET"
    Then the Server error message should be "socket died"
    And the Server error addrinfo should be "127.0.0.1"
    And the Server error original_error should be "ECONNRESET"

  Scenario: ClientConnectionResetError inherits from StandardError
    Given the Server module is loaded
    When I create a Server ClientConnectionResetError with defaults
    Then the Server error should be a kind of StandardError

  # ---------------------------------------------------------------------------
  #  Server class constants
  # ---------------------------------------------------------------------------
  Scenario: Server class defines performance constants
    Given the Server module is loaded
    Then the Server RECEIVE_BUFFER_SIZE should be 4096
    And the Server SELECT_TIMEOUT should be 0.01
    And the Server MAX_PLAYERS should be 100

  # ---------------------------------------------------------------------------
  #  server_socket private method
  # ---------------------------------------------------------------------------
  Scenario: Server server_socket creates a configured listening socket
    Given the Server module is loaded
    And a bare Server instance is allocated
    When I call server_socket on the bare Server with address "127.0.0.1" and a free port
    Then the Server socket should be a Socket instance
    And the Server socket should be in non-blocking mode
    And the Server listening socket is cleaned up

  # ---------------------------------------------------------------------------
  #  handle_client private method – success path
  # ---------------------------------------------------------------------------
  Scenario: Server handle_client returns a PlayerConnection on success
    Given the Server module is loaded
    And a bare Server instance is allocated
    And PlayerConnection is stubbed for the Server test
    When I call handle_client with a mock socket and addrinfo
    Then the Server handle_client result should be a mock player connection

  # ---------------------------------------------------------------------------
  #  handle_client private method – connection reset path
  # ---------------------------------------------------------------------------
  Scenario: Server handle_client returns nil on ECONNRESET
    Given the Server module is loaded
    And a bare Server instance is allocated
    And PlayerConnection is stubbed to raise ECONNRESET for the Server test
    When I call handle_client with a mock socket and addrinfo
    Then the Server handle_client result should be nil

  # ---------------------------------------------------------------------------
  #  clean_up_children private method
  # ---------------------------------------------------------------------------
  Scenario: Server clean_up_children rescues Interrupt
    Given the Server module is loaded
    And a bare Server instance is allocated
    And Process.wait is stubbed to raise Interrupt for the Server test
    When I call clean_up_children on the bare Server
    Then the Server clean_up_children should complete without error

  # ---------------------------------------------------------------------------
  #  Full Server initialisation loop – accepts a connection then exits
  # ---------------------------------------------------------------------------
  Scenario: Server initialise loop accepts a connection and processes it
    Given the Server module is loaded
    And the full Server test harness is prepared
    When I run the Server constructor with the test harness
    Then the Server harness should have accepted a connection
    And the Server harness ensure block should have run

  # ---------------------------------------------------------------------------
  #  Server loop – maximum players rejection
  # ---------------------------------------------------------------------------
  Scenario: Server rejects connections when at maximum capacity
    Given the Server module is loaded
    And the Server max-capacity test harness is prepared
    When I run the Server constructor with the max-capacity harness
    Then the Server harness should have rejected the connection

  # ---------------------------------------------------------------------------
  #  Server loop – ready_read processes player data
  # ---------------------------------------------------------------------------
  Scenario: Server loop reads data from ready player sockets
    Given the Server module is loaded
    And the Server read-ready test harness is prepared
    When I run the Server constructor with the read-ready harness
    Then the Server harness player should have received data

  # ---------------------------------------------------------------------------
  #  Server loop – ready_read error handling
  # ---------------------------------------------------------------------------
  Scenario: Server loop handles read errors by removing the player
    Given the Server module is loaded
    And the Server read-error test harness is prepared
    When I run the Server constructor with the read-error harness
    Then the Server harness should have handled the read error

  # ---------------------------------------------------------------------------
  #  Server loop – ready_error handling
  # ---------------------------------------------------------------------------
  Scenario: Server loop handles error-condition sockets
    Given the Server module is loaded
    And the Server error-condition test harness is prepared
    When I run the Server constructor with the error-condition harness
    Then the Server harness should have handled the error condition

  # ---------------------------------------------------------------------------
  #  Server loop – closed player cleanup
  # ---------------------------------------------------------------------------
  Scenario: Server loop cleans up closed player connections
    Given the Server module is loaded
    And the Server closed-player test harness is prepared
    When I run the Server constructor with the closed-player harness
    Then the Server harness should have cleaned up the closed player

  # ---------------------------------------------------------------------------
  #  Server loop – action processing
  # ---------------------------------------------------------------------------
  Scenario: Server loop processes queued actions
    Given the Server module is loaded
    And the Server action-processing test harness is prepared
    When I run the Server constructor with the action-processing harness
    Then the Server harness action should have been executed

  # ---------------------------------------------------------------------------
  #  Server loop – global refresh
  # ---------------------------------------------------------------------------
  Scenario: Server loop triggers layout on global refresh
    Given the Server module is loaded
    And the Server global-refresh test harness is prepared
    When I run the Server constructor with the global-refresh harness
    Then the Server harness player display should have been laid out

  # ---------------------------------------------------------------------------
  #  Server ensure block – $manager cleanup
  # ---------------------------------------------------------------------------
  Scenario: Server ensure block stops and saves via manager
    Given the Server module is loaded
    And the Server ensure-block test harness is prepared
    When I run the Server constructor with the ensure-block harness
    Then the Server harness manager should have been stopped
    And the Server harness manager should have saved all

  # ---------------------------------------------------------------------------
  #  Aethyr.main method – no ARGV (else branch)
  # ---------------------------------------------------------------------------
  Scenario: Aethyr main method handles server startup and errors
    Given the Server module is loaded
    And Server.new is stubbed to raise RuntimeError for the main test
    When I call Aethyr.main
    Then the Aethyr main method should have raised and rescued the error

  # ---------------------------------------------------------------------------
  #  Aethyr.main method – with ARGV restart count (if branch)
  # ---------------------------------------------------------------------------
  Scenario: Aethyr main with ARGV argument
    Given the Server module is loaded
    And Server.new is stubbed to raise RuntimeError for the main test
    And ARGV contains a restart count for the Server test
    When I call Aethyr.main
    Then the Aethyr main method should have processed the restart count
