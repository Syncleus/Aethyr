# frozen_string_literal: true

# =============================================================================
#  Intro Banner Integration Steps
# -----------------------------------------------------------------------------
#  Provides Cucumber step definitions that spin up a full Aethyr server via the
#  public CLI (`bin/aethyr`) on an ephemeral port, establish a raw TCP socket
#  connection and verify that the introductory banner defined in `intro.txt`
#  is delivered to the client.  The implementation purposefully avoids the
#  ServerHarness utility to ensure we execute through the `Aethyr.main` code
#  path thereby exercising the server bootstrap logic exposed by the CLI.
# =============================================================================

require 'test/unit/assertions'
require 'aruba/api'
require 'socket'
require 'fileutils'
require 'yaml'
require 'timeout'
require 'tmpdir'

World(Test::Unit::Assertions)
World(Aruba::Api)

# -----------------------------------------------------------------------------
#  Helper – obtain an OS-allocated free TCP port (returns Integer)
# -----------------------------------------------------------------------------
#  Creates a short-lived TCPServer bound to port 0 (ephemeral) so the OS
#  selects an unused port, captures it, closes the socket and returns the port
#  number. This guarantees the port will be available for the upcoming server
#  boot sequence while minimising race-condition windows.
# -----------------------------------------------------------------------------

def next_free_tcp_port
  server = TCPServer.new('127.0.0.1', 0)
  port   = server.addr[1]
  server.close
  port
end

# -----------------------------------------------------------------------------
#  Step: Given I start the Aethyr server on a random port
# -----------------------------------------------------------------------------
Given('I start the Aethyr server on a random port') do
  @test_port = next_free_tcp_port

  # -------------------------------------------------------------------------
  #  Temporarily patch the canonical configuration file so the CLI starts the
  #  server on our random, test-specific port.  The original file is restored
  #  in the After-hook to avoid cross-scenario contamination.
  # -------------------------------------------------------------------------
  @config_path      = File.expand_path('/app/conf/config.yaml')
  @original_config  = File.read(@config_path)

  patched_config    = YAML.load(@original_config)
  patched_config[:port] = @test_port
  File.open(@config_path, 'w') { |f| YAML.dump(patched_config, f) }

  # -------------------------------------------------------------------------
  #  Launch the server **as a child process** (background) via the public CLI
  # -------------------------------------------------------------------------
  cli_cmd = "bash -c \"cd /app && bundle exec bin/aethyr run\""
  @server_pid = Process.spawn(cli_cmd, out: '/dev/null', err: '/dev/null')

  #  Ensure the TCP port becomes reachable before the scenario continues.
  Timeout.timeout(30) do
    loop do
      begin
        TCPSocket.new('127.0.0.1', @test_port).close
        break
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        sleep 0.1
      end
    end
  end

  # Restore original configuration file (critical for subsequent scenarios)
  if defined?(@original_config) && @original_config && File.exist?(@config_path)
    File.open(@config_path, 'w') { |f| f.write(@original_config) }
  end
end

# -----------------------------------------------------------------------------
#  Step: When I establish a raw TCP connection to the server
# -----------------------------------------------------------------------------
When('I establish a raw TCP connection to the server') do
  @client_socket = TCPSocket.new('127.0.0.1', @test_port)
  # Disable Nagle for snappier reads
  @client_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
end

# -----------------------------------------------------------------------------
#  Step: Then I should receive the intro banner
# -----------------------------------------------------------------------------
Then('I should receive the intro banner') do
  expected_snippet = 'Welcome to the'
  received_data    = +'' # mutable String with UTF-8 encoding

  Timeout.timeout(20) do
    loop do
      chunk = @client_socket.readpartial(4096) rescue nil
      break unless chunk
      received_data << chunk.force_encoding('UTF-8')
      break if received_data.include?(expected_snippet)
    end
  end

  assert(received_data.include?(expected_snippet),
         "Intro banner was not received from server.\nReceived:\n#{received_data}")
end

# -----------------------------------------------------------------------------
#  Teardown – ensure background artefacts are cleaned up regardless of outcome
# -----------------------------------------------------------------------------
After do
  # Close client socket if it exists
  if defined?(@client_socket) && @client_socket && !@client_socket.closed?
    @client_socket.close rescue nil
  end

  # Terminate the spawned server process
  if defined?(@server_pid) && @server_pid
    begin
      Process.kill('TERM', @server_pid)
      Timeout.timeout(10) { Process.wait(@server_pid) }
    rescue Errno::ESRCH, Errno::ECHILD, Timeout::Error
      # Process already terminated or could not be waited on – swallow
    end
  end
end 