#!/usr/bin/env ruby
=begin
Homepage:       http://jeffreyfreeman.me
Author:         Jeffrey Phillips Freeman
Copyright:      2018, Jeffrey Phillips Freeman
License:        Apache v2

    Copyright 2017 - 2018, Jeffrey Phillips Freeman

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end
$AETHYR_VERSION = "1.0.0"
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'eventmachine'
require 'concurrent'
require 'socket'
require 'aethyr/core/util/config'
require 'aethyr/core/util/log'
require 'aethyr/core/components/manager'
require 'aethyr/core/connection/player_connect'
require 'aethyr/core/render/display'

module Aethyr
    # Custom exception class that represents connection reset errors in client handling
    # This provides better semantic information than simply returning nil
    class ClientConnectionResetError < StandardError
      # Creates a new instance of ClientConnectionResetError
      #
      # @param message [String] The error message to be displayed
      # @param addrinfo [Addrinfo] Information about the client address that experienced the reset
      # @param original_error [Exception] The original network error that triggered this exception
      def initialize(message = "Client connection reset", addrinfo = nil, original_error = nil)
        @addrinfo = addrinfo
        @original_error = original_error
        super(message)
      end
      
      # Client address information where the reset occurred
      # @return [Addrinfo] The client address information
      attr_reader :addrinfo
      
      # The original network error that caused this exception
      # @return [Exception] The original exception object
      attr_reader :original_error
    end

    #The Server is what starts everything up. In fact, that is pretty much all it does. To use, call Server.new.
    class Server
      # Cache frequently used configuration values
      RECEIVE_BUFFER_SIZE = 4096
      SELECT_TIMEOUT = 0.01  # 10ms select timeout for better responsiveness
      MAX_PLAYERS = 100      # Maximum number of players to accept
      
      #This is the main server loop. Just call it.
      #Creates the Manager, starts the EventMachine, and closes everything down when the time comes.
      def initialize(address, port)
        $manager = Manager.new

        # Create timer tasks with better performance settings
        updateTask = Concurrent::TimerTask.new(
          execution_interval: ServerConfig.update_rate,
          timeout_interval: 10,
          run_now: true
        ) do
          $manager.update_all
        end
        
        saveTask = Concurrent::TimerTask.new(
          execution_interval: ServerConfig.save_rate,
          timeout_interval: 30
        ) do
          log "Automatic state save."
          $manager.save_all
        end

        updateTask.execute
        saveTask.execute

        listener = server_socket(address, port)

        # Pre-allocate file handle for logging to avoid reopening it each time
        server_log = File.open("logs/server.log", "a")
        server_log.puts "#{Time.now} Server started."
        server_log.flush
        
        log "Server up and running on #{address}:#{port}", 0

        # Use a more efficient Set for tracking players
        players = Set.new
        
        # Pre-allocate arrays for select to avoid GC churn
        read_array = [listener]
        write_array = []
        error_array = []
        
        loop do
          # Use non-blocking accept with a timeout to avoid high CPU usage
          begin
            socket, addr_info = listener.accept_nonblock(exception: false)
            if socket.is_a?(Socket)
              # Only accept new connections if below the maximum limit
              if players.size < MAX_PLAYERS
                players << handle_client(socket, addr_info)
                read_array << socket
              else
                socket.close
                log "Maximum player limit reached, rejecting connection", Logger::Medium, true
              end
            end
          rescue IO::WaitReadable
            # No connection available, just continue
          rescue StandardError => e
            log "Error accepting connection: #{e.message}", Logger::Medium, true
          end

          # Use optimized IO multiplexing with timeout
          ready_read, ready_write, ready_error = IO.select(read_array, nil, error_array, SELECT_TIMEOUT)
          
          # Process any readable sockets
          if ready_read
            ready_read.each do |socket|
              # Skip listener socket which is handled above
              next if socket == listener
              
              # Find the player connection for this socket
              player = players.find { |p| p.socket == socket }
              next unless player
              
              begin
                player.receive_data
              rescue StandardError => e
                # Handle socket errors by closing the connection
                log "Error reading from player socket: #{e.message}", Logger::Medium, true
                player.close
                read_array.delete(socket)
                players.delete(player)
              end
            end
          end
          
          # Handle any error conditions
          if ready_error
            ready_error.each do |socket|
              player = players.find { |p| p.socket == socket }
              if player
                player.close
                read_array.delete(socket)
                players.delete(player)
              end
            end
          end
          
          # Clean up closed players in batch
          closed_players = players.select(&:closed?)
          if closed_players.any?
            closed_players.each do |player|
              log "Player #{player} has closed connection, removing from server queue"
              read_array.delete(player.socket) if player.socket
              players.delete(player)
            end
          end

          # Process queued actions
          next_action = $manager.pop_action
          next_action.action if next_action

          # Check if global refresh is needed (optimization: only check when players exist)
          if players.any?
            need_refresh = players.any? { |player| player.display.global_refresh }
            if need_refresh
              players.each do |player|
                player.display.layout
              end
            end
          end
        end

        clean_up_children
        return 0 # Return code

      rescue Interrupt => i
        log "Received interrupt: halting", 0
        log i.inspect
        log i.backtrace.join("\n"), 0, true
      rescue Exception => e
        log e.backtrace.join("\n"), 0, true
        log e.inspect
      ensure
        # Close the server log file
        server_log.close if server_log && !server_log.closed?
        
        # Only attempt to shut down / persist state if the Manager
        # successfully initialised – `$manager` will be nil when an
        # exception is raised *before* assignment and we do not want to
        # mask the original failure with a secondary NoMethodError.
        if defined?($manager) && $manager
          $manager.stop
          log "Saving objects...", Logger::Normal, true
          $manager.save_all
          log "Objects saved.", Logger::Normal, true
        end
      end

      private
      def server_socket(addr, port)
        socket = Socket.new(:INET, :SOCK_STREAM)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
        
        # Set TCP_NODELAY for better interactive performance
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
        
        # Increase socket buffer sizes for better performance
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVBUF, 262144)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF, 262144)
        
        socket.bind(Addrinfo.tcp(addr, port))
        socket.listen(5)  # Increase backlog to 5 for better connection handling
        
        # Set non-blocking mode
        socket.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
        
        # Informative start-up message routed through the logger.
        log 'Waiting for connections...', Logger::Ultimate
        socket
      end

      def handle_client(socket, addrinfo)
        begin
          # Set TCP_NODELAY on client sockets too
          socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
          
          player = PlayerConnection.new(socket, addrinfo)
          log "Connected: #{addrinfo.inspect}", Logger::Normal, true
          return player
        rescue Errno::ECONNRESET, Errno::EPIPE => e
          log "Reset: #{addrinfo.inspect}\n#{e.inspect}\n#{e.backtrace.join("\n")}", Logger::Medium, true
          raise ClientConnectionResetError.new("Client connection reset or pipe error", addrinfo, e)
        end
      end

      def clean_up_children
        loop do
          Process.wait # Gather processes as they exit
        end
      rescue Interrupt
        Process.kill('HUP', 0) # Kill all children when main process is terminated
      rescue SystemCallError
        # Final shutdown notification through logger.
        log 'All children have exited. Goodbye!', Logger::Ultimate
      end
    end

    def self.main
          if ARGV[0]
            server_restarts = ARGV[0].to_i
          else
            server_restarts = 0
          end

          log "Server restart ##{server_restarts}"

          begin
            #result = RubyProf.profile do
            Server.new(ServerConfig.address, ServerConfig.port)
            #end
            #File.open "logs/profile", "w" do |f|
            # RubyProf::CallTreePrinter.new(result).print f, 1
            #end
          ensure
            if server_restarts < ServerConfig.restart_limit
              if $manager and $manager.soft_restart
                log "Server restart initiated by administrator."
                File.open("logs/server.log", "a+") { |f| f.puts "#{Time.now} Server restart by administrator." }
              else
                File.open("logs/server.log", "a+") { |f| f.puts "#{Time.now} Server restart on error or interrupt." }
              end

              log "SERVER RESTARTING - Attempting to restart in 10 seconds...press ^C to stop...", Logger::Important
              sleep ServerConfig.restart_delay
              log "RESTARTING SERVER", Logger::Important, true

              program_name = ENV["_"] || "ruby"

              if $manager and $manager.soft_restart
                exec("#{program_name} server.rb")
              else
                exec("#{program_name} server.rb #{server_restarts + 1}")
              end
            else
              File.open("logs/server.log", "a") { |f| f.puts "#{Time.now} Server stopping. Too many restarts." }
              log "Too many restarts, giving up.", Logger::Important, true
            end
          end
    end
end
