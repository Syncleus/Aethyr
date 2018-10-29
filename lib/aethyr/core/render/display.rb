require "ncursesw"
require 'aethyr/core/connection/telnet_codes'

class Display
  PREAMBLE = [IAC + DO + OPT_LINEMODE, 
              IAC + SB + OPT_LINEMODE + OPT_ECHO + OPT_BINARY + IAC + SE,
              IAC + WILL + OPT_ECHO]
            
  DEFAULT_HEIGHT = 130
  DEFAULT_WIDTH = 164
  
  def initialize socket
    @height = DEFAULT_HEIGHT
    @width = DEFAULT_WIDTH
    
    @socket = socket
    PREAMBLE.each do |line|
      @socket.puts line
    end
    
    @selected = :input
    @screen = Ncurses.newterm("vt100", @socket, @socket)
    
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
  
  def layout( layout_type: :full)
    case layout_type
    when :basic
      @window_main = Ncurses::WINDOW.new(@height - 3, 0, 0, 0)
      Ncurses.scrollok(@window_main, true)
      @window_main.clear
      @window_main.move(@window_main.getmaxy - 2,1)

      @window_input = Ncurses::WINDOW.new(3, 0, @height - 3, 0)
      Ncurses.scrollok(@window_input, false)
      @window_input.clear
    when :full
      @window_map = Ncurses::WINDOW.new(@height - 30, 0, 0, 0)
      Ncurses.scrollok(@window_map, true)
      @window_map.clear
      @window_map.move(@window_map.getmaxy - 2,1)
      
      @window_look = Ncurses::WINDOW.new(26, 82, @height - 29, 0)
      Ncurses.scrollok(@window_look, true)
      @window_look.clear
      @window_look.move(@window_look.getmaxy - 2,1)
      
      @window_main = Ncurses::WINDOW.new(26, 0, @height - 29, 82)
      Ncurses.scrollok(@window_main, true)
      @window_main.clear
      @window_main.move(@window_main.getmaxy - 2,1)

      @window_input = Ncurses::WINDOW.new(3, 0, @height - 3, 0)
      Ncurses.scrollok(@window_input, false)
      @window_input.clear
    end

    @echo = true
    update
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
    recvd = read_line(@window_input.getmaxy - 2, 1)

    puts "read returned: #{recvd}"
    recvd + "\n"
  end
  
  def send_raw message
    @socket.puts message
  end
  
  def send (message, message_type: :main, internal_clear: true)
    window = nil
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
    
    message = message.tr("\r", '')
    lines = message.split("\n");
    return if lines.empty?
    if lines.length > 1
      lines.each do |line|
        send line, message_type: message_type, internal_clear: false
      end
      return
    end
    message = lines[0]
    
    set_term

    #window.scroll
    #window.mvaddstr(window.getmaxy - 2, 1, "#{message}\n")
    window.addstr "#{message}\n"
    update
  end
  
  def close
    set_term
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end
  
  private
  
  def update
    @window_main.border(*([32]*8)) unless @window_main.nil?
    @window_input.border(*([32]*8)) unless @window_input.nil?
    @window_map.border(*([32]*8)) unless @window_map.nil?
    @window_look.border(*([32]*8)) unless @window_look.nil?
    
    @window_main.border(*([0]*8)) if @selected.eql? :main
    @window_input.border(*([0]*8)) if @selected.eql? :input
    @window_map.border(*([0]*8)) if @selected.eql? :map
    @window_look.border(*([0]*8)) if @selected.eql? :look
    
    @window_main.noutrefresh()
    @window_input.noutrefresh()
    @window_map.noutrefresh()
    @window_look.noutrefresh()
    Ncurses.doupdate()
  end
  
  def set_term
    Ncurses.set_term(@screen)
  end
  

  def read_line(y, x,
                window     = @window_input,
                max_len    = (window.getmaxx - x - 1),
                string     = "",
                cursor_pos = 0)
    loop do
      window.mvaddstr(y,x,string)
      window.move(y,x+cursor_pos)
      update
      
      ch = window.getch
      puts ch if echo?
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
        @window_main.addstr("≫≫≫≫≫ #{string}\n")
        update
        return string#, cursor_pos, ch # Which return key has been used?
      #when Ncurses::KEY_BACKSPACE
      when 127 # backspace
        string = string[0...([0, cursor_pos-1].max)] + string[cursor_pos..-1]
        cursor_pos = [0, cursor_pos-1].max
        window.mvaddstr(y, x+string.length, " ")
      # when etc...
      when 32..255 # remaining printables
        if (cursor_pos < max_len)
          #string[cursor_pos,0] = ch
          string = string + ch.chr
          cursor_pos += 1
        end
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