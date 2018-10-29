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
  attr_reader :in_buffer, :display
  attr_accessor :color_settings, :use_color, :word_wrap
  
  def initialize(display, addrinfo, *args)
    super(*args)
    @display = display

    @in_buffer = []
    @paginator = nil
    @color_settings = color_settings || to_default
    @use_color = false
    @mccp_to_client = false
    @mccp_from_client = false
    @word_wrap = 120
    @closed = false
    @state = :server_menu
    @login_name = nil
    @login_password = nil
    @password_attempts = 0
    @player = nil
    @expect_callback = nil
    @ip_address = Socket.unpack_sockaddr_in(addrinfo)[1]
    @color_stack = []

    print(File.read(ServerConfig.intro_file), false) if File.exist? ServerConfig.intro_file

    ask_mssp if ServerConfig[:mssp]

    ask_mccp if ServerConfig[:mccp]

    show_server_menu

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

  def send_data message
    message = compress message if @mccp_to_client
    
    @display.send message
  end

  #Sets colors to defaults
  def to_default
    @use_color = false
    @color_settings = {
      "roomtitle" => "fg:green bold",
      "object" => "fg:blue",
      "player" => "fg:cyan",
      "mob" => "fg:yellow bold",
      "merchant" => "fg:yellow dim",
      "me" => "fg:white bold",
      "exit" => "fg:green",
      "say" => "fg:white bold",
      "tell" => "fg:cyan bold",
      "important" => "fg:red bold",
      "editor" => "fg:cyan",
      "news" => "fg:cyan bold",
      "identifier" => "fg:magenta bold",
      "water" => "fg:blue",
      "waterlow" => "fg:blue dim",
      "waterhigh" => "fg:blue bold",
      "earth" => "fg:dark_goldenrod",
      "earthlow" => "fg:dark_goldenrod dim",
      "earthhigh" => "fg:dark_goldenrod bold",
      "air" => "fg:white",
      "airlow" => "fg:white dim",
      "airhigh" => "fg:white bold",
      "fire" => "fg:red",
      "firelow" => "fg:red dim",
      "firehigh" => "fg:red bold",
      "regular" => "fg:gray"
    }
  end

  #Checks if the io connection is nil or closed
  def closed?
    @closed
  end

  #Sends message followed by a newline. Also capitalizes
  #the first letter in the message.
  def send_puts message
    message = message.to_s
    first = message.index(/[a-zA-Z]/)
    message[first,1] = message[first,1] unless first.nil?
    self.print(message, true, true)
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
  def print(message, parse = true, newline = false)
    unless closed?
      if parse
        colorize message
        message.gsub!(/\t/, '     ')
        message = paginate(message)
      end
      if newline and message[-1..-1] != "\n"
        if message[-2..-2] == "\r"
          message << "\n"
        else
          message << "\r\n"
        end
      end
      if @use_color
        regular_format = FormatState.new(@color_settings["regular"])
        message = regular_format.apply + message + regular_format.revert
      end
      send_data message
    end
  end

  def paginate message
    if @player.nil?
      return line_wrap(message)
    elsif not @player.page_height
      return line_wrap(message)
    #elsif not @word_wrap
      #return message.gsub(/([^\r]?)\n/, '\1' + "\r\n")
    end

    ph = @player.page_height

    out = []
    #message = message.gsub(/((\e\[\d+[\;]{0,1}\d*[\;]{0,1}\d*m|[^\r\n\n\s\Z]){#@word_wrap})/, "\\1 ") if @word_wrap
    message = wrap(message, @word_wrap).join("\r\n") if @word_wrap
    message.scan(/((((\e\[\d+[\;]{0,1}\d*[\;]{0,1}\d*m)|.){1,#{@word_wrap}})(\r\n|\n|\s+|\Z))|(\r\n|\n)/) do |m|
      if $2
        out << $2
      else
        out << ""
      end
    end

    if out.length < ph
      return out.join("\r\n")
    end

    @paginator = KPaginator.new(self, out)
    @paginator.more
  end

  #Only use if there is no line height
  def line_wrap message
    message = wrap(message, @word_wrap).join("\n") if @word_wrap
    #message = message.gsub(/((\e\[\d+[\;]{0,1}\d*[\;]{0,1}\d*m|[^\r\n\n\s\Z]){#{@word_wrap}})/, "\\1 ") if @word_wrap
    message.gsub(/(((\e\[\d+[\;]{0,1}\d*[\;]{0,1}\d*m)|.){1,#{@word_wrap}})(\r\n|\n|\s+|\Z)/, "\\1\n")
  end

  #Next page of paginated output
  def more
    if @paginator and @paginator.more?
      self.print(@paginator.more, false)
      if not @paginator.more?
        @paginator = nil
      end
    else
      @paginator = nil
      self.puts "There is no more."
    end
  end

  #Sets the colors in the string according to the player's preferences.
  def colorize string
    colors = @color_settings.keys.dup
    colors << "raw[^>]*"
    colors = colors.join("|")
    if @use_color
      string.gsub!(/<([\/]{0,1})(#{colors})>/i) do |setting|
        if ($1.nil?) || ($1.length <= 0)
          color_encode($2) 
        else
          color_decode($2)
        end
      end
      #string.gsub!(/<\/([^>]*)>/, @@colors[@color_settings["regular"]])
      #string.gsub!(/(\"(.*?)")/, @color_settings["quote"] + '\1' + @color_settings["regular"])
    else
      string.gsub!(/<([^>]*)>/i, "")
      string.gsub!(/<\/([^>]*)>/, "")
    end
    
    string
  end
  
  def color_encode(code)
    parent = @color_stack[-1]
    code = code.downcase
    unless code.start_with? "raw "
      result = FormatState.new(@color_settings[code], parent)
    else
      /raw (?<code>.*)/ =~ code
      result = FormatState.new(code, parent)
    end
    @color_stack << result
    result.apply
  end
  
  def color_decode(code)
    @color_stack.pop.revert
  end

  #Sets the foreground color for a given setting.
  def set_fg_color(code, color)
    code.downcase! unless code.nil?
    color.downcase! unless color.nil?

    if not @color_settings.has_key? code
      "No such setting: #{code}"
    else
      if not @use_color
        @color_settings.keys.each do |setting|
          @color_settings[setting] = ""
        end
        @use_color = true
      end

      @color_settings[code] = color
      "Set #{code} to <#{code}>#{color}</#{code}>."
    end
  end

  #Returns list of color settings to show the player
  def show_color_config
  <<-CONF
Colors are currently: #{@use_color ? "Enabled" : "Disabled"}
Text                Setting          Color
-----------------------------------------------
Room Title          roomtitle        <roomtitle>#{@color_settings['roomtitle']}</roomtitle>
Object              object           <object>#{@color_settings['object']}</object>
Player              player           <player>#{@color_settings['player']}</player>
Mob                 mob              <mob>#{@color_settings['mob']}</mob>
Merchant            merchant         <merchant>#{@color_settings['merchant']}</merchant>
Me                  me               <me>#{@color_settings['me']}</me>
Exit                exit             <exit>#{@color_settings['exit']}</exit>
Say                 say              <say>#{@color_settings['say']}</say>
Tell                tell             <tell>#{@color_settings['tell']}</tell>
Important           important        <important>#{@color_settings['important']}</important>
Editor              editor           <editor>#{@color_settings['editor']}</editor>
News                news             <news>#{@color_settings['news']}</news>
Identifier          identifier       <identifier>#{@color_settings['identifier']}</identifier>
Fire                fire             <fire>#{@color_settings['fire']}</fire>
Fire when low       firelow          <firelow>#{@color_settings['firelow']}</firelow>
Fire when high      firehigh         <firehigh>#{@color_settings['firehigh']}</firehigh>
Air                 air              <air>#{@color_settings['air']}</air>
Air when low        airlow           <airlow>#{@color_settings['airlow']}</airlow>
Air when high       airhigh          <airhigh>#{@color_settings['airhigh']}</airhigh>
Water               water            <water>#{@color_settings['water']}</water>
Water when low      waterlow         <waterlow>#{@color_settings['waterlow']}</waterlow>
Water when high     waterhigh        <waterhigh>#{@color_settings['waterhigh']}</waterhigh>
Earth               earth            <earth>#{@color_settings['earth']}</earth>
Earth when low      earthlow         <earthlow>#{@color_settings['earthlow']}</earthlow>
Earth when high     earthhigh        <earthhigh>#{@color_settings['earthhigh']}</earthhigh>
Regular             regular          #{@color_settings['regular']}
CONF

  end

  #Close the io connection
  def close
    close_connection_after_writing
  end

  def ask_mccp
    log "asking mccp"
    @display.send_raw IAC + WILL + OPT_COMPRESS2
  end

  def ask_mssp
    log "asking mssp"
    @display.send_raw IAC + WILL + OPT_MSSP
  end

  def send_mssp
    log "sending mssp"
    mssp_options = nil
    options = IAC + SB + OPT_MSSP

    if File.exist? "conf/mssp.yaml"
      File.open "conf/mssp.yaml" do |f|
        mssp_options = YAML.load(f)
      end

      mssp_options.each do |k,v|
        options << (MSSP_VAR + k + MSSP_VAL + v.to_s)
      end
    end

    options << (MSSP_VAR + "PLAYERS" + MSSP_VAL + $manager.find_all("class", Player).length.to_s)
    options << (MSSP_VAR + "UPTIME" + MSSP_VAL + $manager.uptime.to_s)
    options << (MSSP_VAR + "ROOMS" + MSSP_VAL + $manager.find_all("class", Room).length.to_s)
    options << (MSSP_VAR + "AREAS" + MSSP_VAL + $manager.find_all("class", Area).length.to_s)
    options << (MSSP_VAR + "ANSI" + MSSP_VAL + "1")
    options << (MSSP_VAR + "FAMILY" + MSSP_VAL + "CUSTOM")
    options << (MSSP_VAR + "CODEBASE" + MSSP_VAL + "Aethyr " + $AETHYR_VERSION)
    options << (MSSP_VAR + "PORT" + MSSP_VAL + ServerConfig.port.to_s)
    options << (MSSP_VAR + "MCCP" + MSSP_VAL + (ServerConfig[:mccp] ? "1" : "0"))
    options << (IAC + SE)
    @display.send_raw options
  end

  #Use zlib to compress message (for MCCP)
  def compress message
    begin
      @mccp_to_client.deflate message, Zlib::SYNC_FLUSH
    rescue Zlib::DataError
      message
    end
  end

  #Use zlib to decompress message (for MCCP)
  def decompress message
    p message
    #message =  "\x78\x01" + message

    begin
      Zlib::Inflate.inflate message
    rescue Zlib::DataError
      message
    end
  end

  #Pulled straight out of standard net/telnet lib.
  #Orginal version by Wakou Aoyama <wakou@ruby-lang.org>
  def preprocess_input string
    if @mccp_from_client
      string = decompress string
    end
    # combine CR+NULL into CR
    string = string.gsub(/#{CR}#{NULL}/no, CR)

      # combine EOL into "\n"
      string = string.gsub(/#{EOL}/no, "\n")

      string.gsub!(/#{IAC}(
        [#{IAC}#{AO}#{AYT}#{DM}#{IP}#{NOP}]|
        [#{DO}#{DONT}#{WILL}#{WONT}]
    [#{OPT_BINARY}-#{OPT_COMPRESS2}#{OPT_EXOPL}]|
    #{SB}[^#{IAC}]*#{IAC}#{SE}
    )/xno) do
      if    IAC == $1  # handle escaped IAC characters
        IAC
      elsif AYT == $1  # respond to "IAC AYT" (are you there)
        send_data("nobody here but us pigeons" + EOL)
        ''
      elsif DO == $1[0,1]  # respond to "IAC DO x"
        if OPT_BINARY == $1[1,1]
          send_data(IAC + WILL + OPT_BINARY)
        elsif OPT_MSSP == $1[1,1]
          send_mssp
        elsif OPT_COMPRESS2 == $1[1,1] and ServerConfig[:mccp]
          begin
            require 'zlib'
            send_data(IAC + SB + OPT_COMPRESS2 + IAC + SE)
            @mccp_to_client = Zlib::Deflate.new
          rescue LoadError
            log "Warning: No zlib - cannot do MCCP"
            send_data(IAC + WONT + $1[1..1])
            return
          end

        else
          #send_data(IAC + WONT + $1[1..1])
        end
        ''
      elsif DONT == $1[0,1]  # respond to "IAC DON'T x" with "IAC WON'T x"
        if OPT_COMPRESS2 == $1[1,1]
          @mccp_to_client = false
          send_data(IAC + WONT + $1[1..1])
        end
        ''
      elsif WILL == $1[0,1]  # respond to "IAC WILL x"
        if OPT_BINARY == $1[1,1]
          send_data(IAC + DO + OPT_BINARY)
        elsif OPT_ECHO == $1[1,1]
          send_data(IAC + DO + OPT_ECHO)
        elsif OPT_SGA  == $1[1,1]
          send_data(IAC + DO + OPT_SGA)
        elsif OPT_COMPRESS2 == $1[1,1]
          send_data(IAC + DONT + OPT_COMPRESS2)
        else
          send_data(IAC + DONT + $1[1..1])
        end
        ''
      elsif WONT == $1[0,1]  # respond to "IAC WON'T x"
        if OPT_ECHO == $1[1,1]
          send_data(IAC + DONT + OPT_ECHO)
        elsif OPT_SGA  == $1[1,1]
          send_data(IAC + DONT + OPT_SGA)
        elsif OPT_COMPRESS2 == $1[1,1]
          @mccp_from_client = false
          send_data(IAC + DONT + OPT_COMPRESS2)
        else
          send_data(IAC + DONT + $1[1..1])
        end
        ''
      else
        ''
      end
    end
    return string
  end
end
