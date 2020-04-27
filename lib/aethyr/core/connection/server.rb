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
          did_something = false
          # handle the listener
          #ready, _, _ = IO.select([listener])
          socket, addr_info = listener.accept_nonblock(exception: false)
          if (not socket.nil?) and socket.is_a? Socket
            players << handle_client(socket, addr_info)
          end

          players.each do |player|
            player.display.set_term
            player.receive_data
          end

        end

#        4.times do # Adjust this number for the pool size
#          next unless fork.nil? # Parent only calls fork
#          loop do # Child does this work
#            handle_client(*listener.accept)
#          end
#          return 0
#        end

        clean_up_children
        return 0 # Return code

#        EventMachine.run do
#          EventMachine.add_periodic_timer(ServerConfig.update_rate) { $manager.update_all }
#          if ServerConfig.save_rate and ServerConfig.save_rate > 0
#            EventMachine.add_periodic_timer(ServerConfig.save_rate * 60) { log "Automatic state save."; $manager.save_all }
#          end
#          EventMachine.start_server address, port, PlayerConnection
#          File.open("logs/server.log", "a") { |f| f.puts "#{Time.now} Server started." }
#          log "Server up and running on #{address}:#{port}", 0
#        end
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
          display = Display.new(socket)
          player = PlayerConnection.new(display, addrinfo)
          puts "Connected: #{addrinfo.inspect}\n"
          return player
        rescue Errno::ECONNRESET, Errno::EPIPE
          puts "       Reset: #{addrinfo.inspect}\n"
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

#      def process_requests(socket)
#        begin
#          # initialize ncurses
#          scr = Ncurses.newterm("vt100", socket, socket)
#          Ncurses.set_term(scr)
#          Ncurses.resizeterm(25, 80)
#          Ncurses.cbreak           # provide unbuffered input
#          Ncurses.noecho           # turn off input echoing
#          Ncurses.nonl             # turn off newline translation
#
#          Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
#          Ncurses.stdscr.keypad(true)     # turn on keypad mode
#
#          Ncurses.stdscr.addstr("Press a key to continue") # output string
#          Ncurses.stdscr.getch                             # get a charachter
#
#          scr = Ncurses.stdscr
#
#          #moving
#          scr.clear() # clear screen
#          scr.move(5,5) # move cursor
#          scr.addstr("move(5,5)")
#          scr.refresh() # update screen
#          sleep(2)
#          scr.move(2,2)
#          scr.addstr("move(2,2)")
#          scr.refresh()
#          sleep(2)
#          scr.move(10, 2)
#
#          # two_borders
#          # make a new window as tall as the screen and half as wide, in the left half
#          # of the screen
#          one = Ncurses::WINDOW.new(0, Ncurses.COLS() / 2, 0, 0)
#          # make one for the right half
#          two = Ncurses::WINDOW.new(0, Ncurses.COLS() - (Ncurses.COLS() / 2),
#                  0, Ncurses.COLS() / 2)
#          one.border(*([0]*8))
#          two.border(*([0]*8))
#          one.move(3,3)
#          two.move(2,5)
#          one.addstr("move(3,3)")
#          two.addstr("move(2,5)")
#          two.move(5,3)
#          two.addstr("Press a key to continue")
#          one.noutrefresh() # copy window to virtual screen, don't update real screen
#          two.noutrefresh()
#          Ncurses.doupdate() # update read screen
#          two.getch()
#
#        ensure
#          Ncurses.echo
#          Ncurses.nocbreak
#          Ncurses.nl
#          Ncurses.endwin
#        end
#      end
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
