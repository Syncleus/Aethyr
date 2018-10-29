require "ncursesw"
require 'aethyr/core/connection/telnet_codes'

class Display
  PREAMBLE = [IAC + DO + OPT_LINEMODE, 
              IAC + SB + OPT_LINEMODE + OPT_ECHO + OPT_BINARY + IAC + SE,
              IAC + WILL + OPT_ECHO]
            
  HEIGHT = 50
  WIDTH = 82
  
  def initialize socket
    @socket = socket
    PREAMBLE.each do |line|
      @socket.puts line
    end
    
    @selected = :input
    @screen = Ncurses.newterm("vt100", @socket, @socket)
    
    Ncurses.set_term(@screen)
    Ncurses.resizeterm(HEIGHT, WIDTH)
    Ncurses.cbreak           # provide unbuffered input
    Ncurses.noecho           # turn off input echoing
    Ncurses.nonl             # turn off newline translation

    Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
    Ncurses.stdscr.keypad(true)     # turn on keypad mode
    
    Ncurses.scrollok(Ncurses.stdscr, true)
    Ncurses.stdscr.clear
    
    @window_main = Ncurses::WINDOW.new(HEIGHT - 3, 0, 0, 0)
    Ncurses.scrollok(@window_main, true)
    @window_main.clear
    @window_main.move(@window_main.getmaxy - 2,1)
    
    @window_input = Ncurses::WINDOW.new(3, 0, HEIGHT - 3, 0)
    Ncurses.scrollok(@window_input, false)
    @window_input.clear
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
  
  def send (message, window_type: :main)
    message = message.tr("\r", '')
    lines = message.split("\n");
    return if lines.empty?
    if lines.length > 1
      lines.each do |line|
        send line, window_type: window_type
      end
      return
    end
    message = lines[0]
    
    window = nil
    case window_type
    when :main
      window = @window_main
    end
    raise "window_type not recognized" if window.nil?
    
    set_term

    window.scroll
    window.mvaddstr(@window_main.getmaxy - 2, 1, "#{message}\n")
    #window.addstr message + "\n"
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
    if @selected.eql? :main
      @window_main.border(*([0]*8)) 
      @window_input.border(*([32]*8))
    elsif @selected.eql? :input
      @window_main.border(*([32]*8)) 
      @window_input.border(*([0]*8))
    end
    
    @window_main.noutrefresh()
    @window_input.noutrefresh()
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
        puts @selected
        case @selected
        when :input
          @selected = :main
        when :main
          @selected = :input
        else
          @selected = :main
        end
        update
      else
        log "Unidentified key press: #{ch}"
      end
    end    	
  end
end