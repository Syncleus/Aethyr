require "ncursesw"
require 'stringio'
require 'aethyr/core/connection/telnet_codes'
require 'aethyr/core/connection/telnet'
require 'aethyr/core/components/manager'

class Display
  attr_accessor :color_settings, :use_color

  DEFAULT_HEIGHT = 43
  DEFAULT_WIDTH = 80
  BUFFER_SIZE = 10000

  def initialize(socket, new_color_settings = nil)
    @height = DEFAULT_HEIGHT
    @width = DEFAULT_WIDTH
    @use_color = false
    @layout_type = :basic
    @buffer = Hash.new

    @color_stack = []
    @color_settings = new_color_settings || to_default_colors

    @socket = socket #StringIO.new
    @scanner = TelnetScanner.new(socket, self)
    @scanner.send_preamble

    @selected = :input
    @screen = Ncurses.newterm("xterm-256color", @socket, @socket)

    Ncurses.set_term(@screen)
    Ncurses.resizeterm(@height, @width)
    Ncurses.cbreak           # provide unbuffered input
    Ncurses.noecho           # turn off input echoing
    Ncurses.nonl             # turn off newline translation

    Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
    Ncurses.stdscr.keypad(true)     # turn on keypad mode

    Ncurses.scrollok(Ncurses.stdscr, true)
    Ncurses.stdscr.clear

    layout
  end

  def init_colors
    Ncurses.start_color
    @use_color = true
    puts "There are #{Ncurses.COLORS} colors on this client"
    Ncurses.assume_default_colors(Color::Foreground.attribute(:white), Color::Background.attribute(:black));
    Ncurses.COLORS.times do |fg|
      Ncurses.COLORS.times do |bg|
        Ncurses.init_pair(fg + bg * Ncurses.COLORS, fg, bg)
      end
    end
    update
  end

  def activate_color(window, fg, bg)
    return if not @use_color
    #window.attron(fg + bg * Ncurses.COLORS)
    if Ncurses.respond_to?(:color_set)
      window.color_set(fg + bg * Ncurses.COLORS, nil)
    else
      window.attrset(Ncurses.COLOR_PAIR(fg + bg * Ncurses.COLORS))
    end
  end

  def layout
    case @layout_type
    when :basic
      Ncurses.delwin(@window_main_border) unless @window_main_border.nil?
      @window_main_border = Ncurses::WINDOW.new(@height - 3, 0, 0, 0)
      @window_main = @window_main_border.derwin(@window_main_border.getmaxy - 2, @window_main_border.getmaxx - 2, 1, 1)
      Ncurses.scrollok(@window_main, true)
      @window_main.clear
      @window_main.move(@window_main.getmaxy - 2,1)
      @buffer[:main] = [] if @buffer[:main].nil?
      @buffer[:main].each do | message|
        render(message, @window_main)
      end

      Ncurses.delwin(@window_input_border) unless @window_input_border.nil?
      @window_input_border = Ncurses::WINDOW.new(3, 0, @height - 3, 0)
      @window_input = @window_input_border.derwin(@window_input_border.getmaxy - 2, @window_input_border.getmaxx - 2, 1, 1)
      Ncurses.scrollok(@window_input, false)
      @window_input.clear
      @window_input.move(@window_input.getmaxy - 2,1)
    when :full
      Ncurses.delwin(@window_map_border) unless @window_map_border.nil?
      @window_map_border = Ncurses::WINDOW.new(@height - 39, 0, 0, 0)
      @window_map = @window_map_border.derwin(@window_map_border.getmaxy - 2, @window_map_border.getmaxx - 2, 1, 1)
      Ncurses.scrollok(@window_map, true)
      @window_map.clear
      @window_map.move(@window_map.getmaxy - 2,1)

      Ncurses.delwin(@window_look_border) unless @window_look_border.nil?
      @window_look_border = Ncurses::WINDOW.new(36, 82, @height - 39, 0)
      @window_look = @window_look_border.derwin(@window_look_border.getmaxy - 2, @window_look_border.getmaxx - 2, 1, 1)
      Ncurses.scrollok(@window_look, true)
      @window_look.clear
      @window_look.move(@window_look.getmaxy - 2,1)

      Ncurses.delwin(@window_main_border) unless @window_main_border.nil?
      @window_main_border = Ncurses::WINDOW.new(36, 0, @height - 39, 82)
      @window_main = @window_main_border.derwin(@window_main_border.getmaxy - 2, @window_main_border.getmaxx - 2, 1, 1)
      Ncurses.scrollok(@window_main, true)
      @window_main.clear
      @window_main.move(@window_main.getmaxy - 2,1)
      @buffer[:main] = [] if @buffer[:main].nil?
      @buffer[:main].each do | message|
        render(message, @window_main)
      end

      Ncurses.delwin(@window_input_border) unless @window_input_border.nil?
      @window_input_border = Ncurses::WINDOW.new(3, 0, @height - 3, 0)
      @window_input = @window_input_border.derwin(@window_input_border.getmaxy - 2, @window_input_border.getmaxx - 2, 1, 1)
      Ncurses.scrollok(@window_input, false)
      @window_input.clear
      @window_input.move(@window_input.getmaxy - 2,1)
    end

    @echo = true
    update
  end

  def resolution
    [@width, @height]
  end

  def resolution=(resolution)
    @width = resolution[0]
    @height = resolution[1]
    Ncurses.resizeterm(@height, @width)
    @layout_type = :full if @height > 100 && @width > 165
    layout
  end

  def read_rdy?
    ready, _, _ = IO.select([@socket])
    ready.any?
  end

  def echo?
    @echo
  end

  def echo_on
    @echo = true
  end

  def echo_off
    @echo = false
  end

  def recv
    return nil unless read_rdy?

    set_term
    recvd = read_line(0, 0)

    puts "read returned: #{recvd}"
    recvd + "\n"
  end

  def send_raw message
    @socket.puts message
  end

  def send (message, message_type: :main, internal_clear: false, add_newline: true)
    window = nil

    unless @buffer[message_type].nil?
      @buffer[message_type] << message.dup
      @buffer[message_type].drop(@buffer[message_type].length - BUFFER_SIZE) if @buffer[message_type].length > BUFFER_SIZE
    end

    case message_type
    when :main
      window = @window_main
    when :look
      unless @window_look.nil?
        window = @window_look
        #window.clear
      else
        window = @window_main
      end
    when :map
      unless @window_map.nil?
        window = @window_map
        #window.clear
      else
        window = @window_main
      end
    end
    raise "window_type not recognized" if window.nil?

    window.clear if internal_clear and not message_type.eql? :main

    render(message, window, add_newline: add_newline)
  end

  def render(message, window = @window_main, add_newline: true)

    message = message.tr("\r", '')
    lines = message.split("\n");
    return if lines.empty?
    if lines.length > 1
      lines.each do |line|
        render line, window, add_newline: add_newline
      end
      return
    end
    message = lines[0]

    message += "\n" if add_newline
    colored_send(window, message)
  end

  def colored_send(window, message)
    set_term

    regular_format = nil
    if @use_color
      regular_format = FormatState.new(@color_settings["regular"], self.method(:activate_color))
      regular_format.apply(window)
    end

    colors = @color_settings.keys.dup
    colors << "raw[^>]*"
    colors = colors.join("|")

    message.split(/(<[\/]{0,1}[^>]*>)/i).each do |part|
      if part.start_with? "<"
        if @use_color
          part.match(/<([\/]{0,1})([^>]*)>/i) do
            if ($1.nil?) || ($1.length <= 0)
              color_encode(window, $2)
            else
              color_decode(window, $2)
            end
          end
        end
      else
        window.addstr("#{part}")
      end
    end

    if @use_color
      regular_format.revert(window)
    end

    update
  end

  #Send message without newline
  def print(message, parse = true, newline = false, message_type: :main)
    if parse
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
    send( message, message_type: message_type, add_newline: newline)
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

  def close
    set_term
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end

  #Sets colors to defaults
  def to_default_colors
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
      "earth" => "fg:darkgoldenrod",
      "earthlow" => "fg:darkgoldenrod dim",
      "earthhigh" => "fg:darkgoldenrod bold",
      "air" => "fg:white",
      "airlow" => "fg:white dim",
      "airhigh" => "fg:white bold",
      "fire" => "fg:red",
      "firelow" => "fg:red dim",
      "firehigh" => "fg:red bold",
      "regular" => "fg:white bg:black"
    }
  end

  def color_encode(window, code)
    parent = @color_stack[-1]
    code = code.downcase
    code = "regular" if code.nil? || code.empty? || @color_settings[code].nil?
    unless code.start_with? "raw "
      result = FormatState.new(@color_settings[code], self.method(:activate_color), parent)
    else
      /raw (?<code>.*)/ =~ code
      result = FormatState.new(code, self.method(:activate_color), parent)
    end
    @color_stack << result
    result.apply(window)
  end

  def color_decode(window, code)
    @color_stack.pop.revert(window)
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

  def refresh_watch_windows(player)
    unless @window_look.nil?
      if player.blind?
        send( "You cannot see while you are blind.", message_type: :look, internal_clear: true)
      else
        room = $manager.get_object(player.container)
        if not room.nil?
          look_text = room.look(player)
          send(look_text, message_type: :look, internal_clear: true)
        else
          send("Nothing to look at.", message_type: :look, internal_clear: true)
        end
      end
    end

    unless @window_map.nil?
      room = $manager.get_object(player.container)
      if not room.nil?
        send(room.area.render_map(player, room.area.position(room)), message_type: :map, internal_clear: true)
      else
        send("No map of current area.", message_type: :map, internal_clear: true)
      end
    end
  end

  private

  def update

    white_fg = Color::Foreground.attribute(:white)
    grey_fg = Color::Foreground.attribute(:grey)
    black_bg = Color::Background.attribute(:black)

    if @use_color
      activate_color(@window_main_border, grey_fg, black_bg) unless @window_main_border.nil?
      activate_color(@window_input_border, grey_fg, black_bg) unless @window_input_border.nil?
      activate_color(@window_map_border, grey_fg, black_bg) unless @window_map_border.nil?
      activate_color(@window_look_border, grey_fg, black_bg) unless @window_look_border.nil?
    end

    default_border = 0 if @color_enable
    default_border = 32 unless @color_enable
    @window_main_border.border(*([default_border]*8)) unless @window_main_border.nil?
    @window_input_border.border(*([default_border]*8)) unless @window_input_border.nil?
    @window_map_border.border(*([default_border]*8)) unless @window_map_border.nil?
    @window_look_border.border(*([default_border]*8)) unless @window_look_border.nil?

    if @use_color
      activate_color(@window_main_border, white_fg, black_bg) if @selected.eql? :main
      activate_color(@window_input_border, white_fg, black_bg) if @selected.eql? :input
      activate_color(@window_map_border, white_fg, black_bg) if @selected.eql? :map
      activate_color(@window_look_border, white_fg, black_bg) if @selected.eql? :look
    end

    @window_main_border.border(*([0]*8)) if @selected.eql? :main
    @window_input_border.border(*([0]*8)) if @selected.eql? :input
    @window_map_border.border(*([0]*8)) if @selected.eql? :map
    @window_look_border.border(*([0]*8)) if @selected.eql? :look

    @window_main_border.noutrefresh() unless @window_main_border.nil?
    @window_main.noutrefresh() unless @window_main.nil?
    @window_input_border.noutrefresh() unless @window_input_border.nil?
    @window_input.noutrefresh() unless @window_input.nil?
    @window_map_border.noutrefresh() unless @window_map_border.nil?
    @window_map.noutrefresh() unless @window_map.nil?
    @window_look_border.noutrefresh() unless @window_look_border.nil?
    @window_look.noutrefresh() unless @window_look.nil?
    Ncurses.doupdate()
  end

  def set_term
    Ncurses.set_term(@screen)
  end


  def read_line(y, x,
                window: @window_input,
                max_len: (window.getmaxx - x - 1),
                string: "",
                cursor_pos: 0)
    loop do
      window.mvaddstr(y,x,string) if echo?
      window.move(y,x+cursor_pos) if echo?
      update

      next if not @scanner.process_iac
      ch = window.getch
      puts ch
      case ch
      when Ncurses::KEY_LEFT
        cursor_pos = [0, cursor_pos-1].max
      when Ncurses::KEY_RIGHT
        cursor_pos = [max_len, cursor_pos + 1].min
        # similar, implement yourself !
#      when Ncurses::KEY_ENTER, ?\n, ?\r
#        return string, cursor_pos, ch # Which return key has been used?
      when 13 # return
        window.clear
        @window_main.addstr("≫≫≫≫≫ #{string}\n") if echo?
        @selected = :input
        update
        return string#, cursor_pos, ch # Which return key has been used?
      #when Ncurses::KEY_BACKSPACE
      when 127 # backspace
        string = string[0...([0, cursor_pos-1].max)] + string[cursor_pos..-1]
        cursor_pos = [0, cursor_pos-1].max
        window.mvaddstr(y, x+string.length, " ") if echo?
        @selected = :input
      # when etc...
      when 32..255 # remaining printables
        if (cursor_pos < max_len)
          #string[cursor_pos,0] = ch
          string = string + ch.chr
          cursor_pos += 1
        end
        @selected = :input
      when 9 # tab
        case @selected
        when :input
          @selected = :main
        when :main
          if not @window_map.nil?
            @selected = :map
          elsif not @window_look.nil?
            @selected = :look
          else
            @selected = :input
          end
        when :map
          if not @window_look.nil?
            @selected = :look
          else
            @selected = :input
          end
        when :look
          @selected = :input
        else
          @selected = :input
        end
        update
      else
        log "Unidentified key press: #{ch}"
      end
    end
  end
end
