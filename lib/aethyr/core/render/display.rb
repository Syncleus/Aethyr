# coding: utf-8

require 'ncursesw'
require 'stringio'
require 'aethyr/core/connection/telnet_codes'
require 'aethyr/core/connection/telnet'
require 'aethyr/core/components/manager'
require 'aethyr/core/render/window'

class Display
  attr_reader :layout_type
  attr_accessor :color_settings, :use_color

  DEFAULT_HEIGHT = 43
  DEFAULT_WIDTH = 80

  def initialize(socket, new_color_settings = nil)
    @height = DEFAULT_HEIGHT
    @width = DEFAULT_WIDTH
    @use_color = false
    @layout_type = :basic

    @color_settings = new_color_settings || to_default_colors

    @socket = socket # StringIO.new
    @scanner = TelnetScanner.new(socket, self)
    @scanner.send_preamble

    @screen = Ncurses.newterm('xterm-256color', @socket, @socket)

    Ncurses.set_term(@screen)
    Ncurses.cbreak           # provide unbuffered input
    Ncurses.noecho           # turn off input echoing
    Ncurses.nonl             # turn off newline translation
    Ncurses.curs_set(2) # high visibility cursor

    Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
    Ncurses.stdscr.keypad(true)     # turn on keypad mode

    Ncurses.stdscr.clear

    @windows = {
      main: Window.new(@color_settings, buffered: true),
      input: Window.new(@color_settings),
      map: Window.new(@color_settings),
      look: Window.new(@color_settings, buffered: true),
      quick_bar: Window.new(@color_settings),
      status: Window.new(@color_settings),
      chat: Window.new(@color_settings, buffered: true)
    }
    self.selected = :input
    layout
  end

  def init_colors
    Ncurses.start_color
    @use_color = true
    @windows.each do |_channel, window|
      window.enable_color
    end
    puts "There are #{Ncurses.COLORS} colors on this client"
    Ncurses.assume_default_colors(Color::Foreground.attribute(:white), Color::Background.attribute(:black))
    Ncurses.COLORS.times do |fg|
      Ncurses.COLORS.times do |bg|
        Ncurses.init_pair(fg + bg * Ncurses.COLORS, fg, bg)
      end
    end
    update
  end

  def selected=(channel)
    @windows.each do |_channel, window|
      window.selected = false
    end
    @windows[channel].selected = true
  end

  def selected
    @windows.each do |channel, window|
      return channel if window.selected
    end
    :input
  end

  def layout(layout: @layout_type)
    set_term
    puts "layout #{layout} set for resolution #{@width}x#{@height}"
    @layout_type = layout
    if @layout_type == :wide && @height >= 60 && @width >= 300
      @windows[:quick_bar].create(height: 3, y: @height - 5)
      @windows[:map].create(height: @height / 2 + 1, width: 166)
      @windows[:look].create(height: @height / 2 - 3, width: 83, y: @height / 2)
      @windows[:main].create(height: @height / 2 - 3, width: 83, x: 83, y: @height / 2)
      @windows[:chat].create(height: @height - 4, width: @width - 249, x: 166)
      @windows[:status].create(height: @height - 4, x: @width - 83)
    elsif (@layout_type == :full || @layout_type == :wide) && @height >= 60 && @width >= 249
      @windows[:quick_bar].create(height: 3, y: @height - 5)
      @windows[:map].create(height: @height / 2 + 1, width: 166)
      @windows[:look].create(height: @height / 2 - 3, width: 83, y: @height / 2)
      @windows[:main].create(height: @height / 2 - 3, width: 83, x: 83, y: @height / 2)
      @windows[:chat].create(height: @height - 4, x: 166)
      @windows[:status].destroy
    elsif (@layout_type == :partial || @layout_type == :full || @layout_type == :wide) && @height >= 60 && @width >= 166
      @windows[:status].destroy
      @windows[:chat].destroy
      @windows[:quick_bar].create(height: 3, y: @height - 5)
      @windows[:map].create(height: @height / 2 + 1)
      @windows[:look].create(height: @height / 2 - 3, width: 83, y: @height / 2)
      @windows[:main].create(height: @height / 2 - 3, x: 83, y: @height / 2)
    else
      @windows[:map].destroy
      @windows[:look].destroy
      @windows[:quick_bar].destroy
      @windows[:status].destroy
      @windows[:chat].destroy
      @windows[:main].create(height: @height - 2)
    end
    @windows[:input].create(height: 3, y: @height - 3)

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
    @global_refresh = true
    layout
  end

  def global_refresh
    retval = @global_refresh
    @global_refresh = false
    return retval
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
    set_term
    recvd = read_line(0, 0)

    return nil if recvd.nil?

    puts "read returned: #{recvd}"
    recvd + "\n"
  end

  def send_raw(message)
    @socket.puts message
  end

  def send(message, word_wrap = true, message_type: :main, internal_clear: false, add_newline: true)
    window = nil

    if @windows[message_type].nil? || !@windows[message_type].exists?
      message_type = :main
      internal_clear = false
    end

    @windows[message_type].clear if internal_clear
    @windows[message_type].send(message, word_wrap, add_newline: add_newline)
  end

  def close
    set_term
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
    @socket.close
  end

  # Sets colors to defaults
  def to_default_colors
    @color_settings = {
      'roomtitle' => 'fg:green bold',
      'object' => 'fg:blue',
      'player' => 'fg:cyan',
      'mob' => 'fg:yellow bold',
      'merchant' => 'fg:yellow dim',
      'me' => 'fg:white bold',
      'exit' => 'fg:green',
      'say' => 'fg:white bold',
      'tell' => 'fg:cyan bold',
      'important' => 'fg:red bold',
      'editor' => 'fg:cyan',
      'news' => 'fg:cyan bold',
      'identifier' => 'fg:magenta bold',
      'water' => 'fg:blue',
      'waterlow' => 'fg:blue dim',
      'waterhigh' => 'fg:blue bold',
      'earth' => 'fg:darkgoldenrod',
      'earthlow' => 'fg:darkgoldenrod dim',
      'earthhigh' => 'fg:darkgoldenrod bold',
      'air' => 'fg:white',
      'airlow' => 'fg:white dim',
      'airhigh' => 'fg:white bold',
      'fire' => 'fg:red',
      'firelow' => 'fg:red dim',
      'firehigh' => 'fg:red bold',
      'regular' => 'fg:white bg:black'
    }
  end

  # Sets the foreground color for a given setting.
  def set_color(code, color)
    code&.downcase!
    color&.downcase!

    if !@color_settings.key? code
      "No such setting: #{code}"
    else
      unless @use_color
        @color_settings.keys.each do |setting|
          @color_settings[setting] = ''
        end
        @use_color = true
      end

      @color_settings[code] = color
      "Set #{code} to <#{code}>#{color}</#{code}>."
    end
  end

  # Returns list of color settings to show the player
  def show_color_config
    <<~CONF
      Colors are currently: #{@use_color ? 'Enabled' : 'Disabled'}
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
    if @windows[:look].exists?
      room = $manager.get_object(player.container)
      if !room.nil?
        look_text = room.look(player)
        # cleared = false
        msg = Window.split_message(look_text, 79).join("\n")
        send(msg, message_type: :look, internal_clear: true, add_newline: true)
      else
        send('Nothing to look at.', message_type: :look, internal_clear: true)
      end
    end

    if @windows[:map].exists?
      room = $manager.get_object(player.container)
      if !room.nil?
        player.output(room.area.render_map(player, room.area.position(room)), message_type: :map, internal_clear: true)
      else
        player.output('No map of current area.', message_type: :map, internal_clear: true)
      end
    end

    if @windows[:quick_bar].exists?
      send('this is the quick bar', message_type: :quick_bar, internal_clear: true, add_newline: false)
    end

    if @windows[:status].exists?
      send('This is the status window', message_type: :status, internal_clear: true, add_newline: false)
    end
  end

  def set_term
    Ncurses.set_term(@screen)
  end

  private

  def update
    @windows.each do |channel, window|
      window.update unless channel == selected
    end
    @windows[selected].update # make sure the selected window always takes the last update so border renders properly
    Ncurses.doupdate
  end

  def read_line(y, x,
                max_len: (@windows[:input].window_text.getmaxx - x - 1))

    @read_stage = :none if @read_stage.nil?
    if @read_stage == :none
      @escape = nil
      @cursor_pos = 0
      @input_buffer = ''
      @read_stage = :update
    end

    if @read_stage == :update
      @windows[:input].clear
      @windows[:input].window_text.mvaddstr(y, x, @input_buffer) if echo?
      @windows[:input].window_text.move(y, x + @cursor_pos) if echo?
      # update
      @windows[:input].update
      Ncurses.doupdate

      @read_stage = :iac
      return nil
    end

    if @read_stage == :iac
      @read_stage = :input if @scanner.process_iac
      return nil
    end

    ch = @windows[:input].window_text.getch
    @read_stage = :iac
    puts ch

    unless @escape.nil?
      case @escape

      when [27]
        case ch
        when 91
          @escape = [27, 91]
        end

      when [27, 91]
        case ch
        when 53 # scroll up
          @escape = [27, 91, 53]
        when 54 # scroll down
          @escape = [27, 91, 54]
        when 68
          ch = Ncurses::KEY_LEFT
          @escape = nil
        when 67
          ch = Ncurses::KEY_RIGHT
          @escape = nil
        when 65
          ch = Ncurses::KEY_UP
          @escape = nil
        when 66
          ch = Ncurses::KEY_DOWN
          @escape = nil
        else
          @escape = nil
          return nil
        end

      when [27, 91, 53]
        case ch
        when 126 # page up
          if selected == :input
            @windows[:main].buffer_pos += 5
          else
            if (@windows[selected].respond_to? :buffer_pos) && !@windows[selected].buffer_pos.nil?
              @windows[selected].buffer_pos += 5
            end
          end
          @escape = nil
          return nil
        else
          @escape = nil
          return nil
        end

      when [27, 91, 54]
        case ch
        when 126 # page down
          if selected == :input
            @windows[:main].buffer_pos -= 5
          else
            if (@windows[selected].respond_to? :buffer_pos) && !@windows[selected].buffer_pos.nil?
              @windows[selected].buffer_pos -= 5
            end
          end
          @escape = nil
          return nil
        else
          @escape = nil
          return nil
        end
      else
        @escape = nil
        return nil
      end
    end

    if @escape.nil?
      case ch
      when 27
        @escape = [27]
      when Ncurses::KEY_LEFT
        @cursor_pos = [0, @cursor_pos - 1].max
        @read_stage = :update
      when Ncurses::KEY_RIGHT
        @cursor_pos = [max_len, @cursor_pos + 1, @input_buffer.length].min
        @read_stage = :update
      when Ncurses::KEY_UP
        @windows[:main].buffer_pos += 1
        @read_stage = :update
      when Ncurses::KEY_DOWN
        @windows[:main].buffer_pos -= 1
        @read_stage = :update
      when 13 # return
        @windows[:input].clear
        self.selected = :input
        @windows[:main].send("\n≫≫≫≫≫ #{@input_buffer}\n\n") if echo?
        @windows[:main].buffer_pos = 0
        @windows[:main].update
        @read_stage = :none
        return @input_buffer # , cursor_pos, ch # Which return key has been used?
      # when Ncurses::KEY_BACKSPACE
      when 127, "\b".ord, Ncurses::KEY_BACKSPACE # backspace
        # string = string[0...([0, cursor_pos-1].max)] + string[cursor_pos..-1]
        if @cursor_pos >= 1
          @input_buffer.slice!(@cursor_pos - 1)
          @cursor_pos -= 1
        end
        #          window.mvaddstr(y, x+string.length, " ") if echo?
        @selected = :input
        @read_stage = :update
      # when etc...
      when 32..255 # remaining printables
        if @cursor_pos < max_len
          # string[cursor_pos,0] = ch
          @input_buffer.insert(@cursor_pos, ch.chr)
          @cursor_pos += 1
        end
        @selected = :input
        @read_stage = :update
      when 9 # tab
        self.selected = case selected
                        when :input
                          if @windows[:look].exists?
                            :look
                          else
                            :main
                          end
                        when :main
                          if @windows[:chat].exists?
                            :chat
                          elsif @windows[:status].exists?
                            :status
                          else
                            :input
                          end
                        when :map
                          :main
                        when :look
                          if @windows[:map].exists?
                            :map
                          else
                            :input
                          end
                        when :chat
                          if @windows[:status].exists?
                            :status
                          else
                            :input
                          end
                        when :status
                          :input
                        else
                          :input
                        end
        @read_stage = :update
        update
      else
        log "Unidentified key press: #{ch}"
      end
    end

    return nil
  end
end
