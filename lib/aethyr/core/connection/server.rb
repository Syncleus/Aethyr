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
      #This is the main server loop. Just call it.
      #Creates the Manager, starts the EventMachine, and closes everything down when the time comes.
      def initialize(address, port)
        $manager = Manager.new

        updateTask = Concurrent::TimerTask.new(execution_interval: ServerConfig.update_rate, timeout_interval: 10) do
          $manager.update_all
        end
        saveTask = Concurrent::TimerTask.new(execution_interval: ServerConfig.save_rate, timeout_interval: 30) do
          log "Automatic state save."
          $manager.save_all
        end

        updateTask.execute
        saveTask.execute

        listener = server_socket(address, port)

        File.open("logs/server.log", "a") { |f| f.puts "#{Time.now} Server started." }
        log "Server up and running on #{address}:#{port}", 0

        players = Set.new()
        loop do
          # handle the listener
          #ready, _, _ = IO.select([listener])
          socket, addr_info = listener.accept_nonblock(exception: false)
          if (not socket.nil?) and socket.is_a? Socket
            begin
              players << handle_client(socket, addr_info)
            rescue ClientConnectionResetError => e
              log "Player disconnected prematurely", Logger::Medium, true
            end
          end

          players.each do |player|
            if player.closed?
              log "Player #{player} has closed connection, removing from server queue"
              players.delete(player)
            else
              player.receive_data
            end
          end

          next_action = $manager.pop_action
          next_action.action unless next_action.nil?

          # TODO this is a hack to fix a bug from calling resizeterm
          #check if global refresh is needed
          need_refresh = false
          players.each do |player|
            need_refresh = true if player.display.global_refresh
          end
          if need_refresh
            players.each do |player|
              player.display.layout
            end
            #$manager.find_all("class", Player).each do |player|
            #  puts "updating display of #{player}"
            #  player.update_display
            #end
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
        $manager.stop
        log "Saving objects...", Logger::Normal, true
        $manager.save_all
        log "Objects saved.", Logger::Normal, true
      end

      private
      def server_socket(addr, port)
        socket = Socket.new(:INET, :SOCK_STREAM)
        socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
        socket.bind(Addrinfo.tcp(addr, port))
        socket.listen(1)
        puts 'Waiting for connections...'
        socket
      end

      def handle_client(socket, addrinfo)
        begin
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
        puts 'All children have exited. Goodbye!'
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
