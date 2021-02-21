require 'strscan'
require 'socket'
require 'aethyr/core/render/format'
require 'aethyr/core/connection/telnet_codes'
require 'aethyr/core/errors'
require 'aethyr/core/connection/login'
require 'aethyr/core/render/koa_paginator'
require 'aethyr/core/render/editor'
require 'aethyr/core/render/text_util'
include TextUtil

#This is the network connection to the Player. Handles all input/output.
class PlayerConnection
  include Login
  include Editor

  #Input buffer
  attr_reader :in_buffer, :display, :socket
  attr_accessor :word_wrap

  def initialize(socket, addrinfo, *args)
    super(*args)
    @display = Display.new(socket)
    @socket = socket

    @in_buffer = []
    @paginator = nil
    @mccp_to_client = false
    @mccp_from_client = false
    @word_wrap = 120
    @closed = false
    @state = :initial
    @login_name = nil
    @login_password = nil
    @password_attempts = 0
    @player = nil
    @expect_callback = nil
    @ip_address = Socket.unpack_sockaddr_in(addrinfo)[1]

    200.times{print "\n"}
    print(File.read(ServerConfig.intro_file), false) if File.exist? ServerConfig.intro_file

    show_initial

    log "Connection from #{@ip_address}."
  end

  #Returns setting for how long output should be before pagination.
  def page_height
    @player.page_height
  end

  #The next input will be passed to the given block.
  def expect(&block)
    @expect_callback = block
  end

  def ask question, &block
    self.output question
    self.expect do |answer|
       block.call answer
    end
  end

  def ask_menu options, answers = nil, &block
    @player.output options
    self.expect do |answer|
      if answers and not answers.include? answer
        player.menu options, answers, &block
      else
        block.call answer
      end
    end
  end

  #Connection closed
  def unbind
    File.open("logs/player.log", "a") { |f| f.puts "#{Time.now} - #{@player ? @player.name : "Someone"} logged out (#{@ip_address})." }
    log "#{@player ? @player.name: "Someone"} logged out (#{@ip_address}).", Logger::Ultimate
    @closed = true
    @mccp_to_client.finish if @mccp_to_client
    after 3 do
      if @player and $manager.object_loaded? @player.goid
        log "Connection broken, forcing manager to drop #{@player and @player.name}.", Logger::Medium
        $manager.drop_player(@player)
      end
      nil
    end
  end

  #Checks if the io connection is nil or closed
  def closed?
    @closed
  end

  #Sends message followed by a newline. Also capitalizes
  #the first letter in the message.
  def send_puts( message, no_newline = false, message_type: :main, internal_clear: false)
    message = message.to_s
    first = message.index(/[a-zA-Z]/)
    message[first,1] = message[first,1] unless first.nil?
    self.print(message, true, !no_newline, message_type: message_type, internal_clear: internal_clear)
  end

  alias :output :send_puts
  alias :say :send_puts

  #Output an array of messages
  def put_list *messages
    messages.each { |m| self.puts m }
  end

  #Choose your pick
  def choose(prompt, *choices)
  end

  #Send message without newline
  def print(message, parse = true, newline = false, message_type: :main, internal_clear: false)
    @display.send(message, parse, add_newline: newline, message_type: message_type, internal_clear: internal_clear) unless closed?
  end

  #Close the io connection
  def close
    display.close
    @closed = true
  end
end
