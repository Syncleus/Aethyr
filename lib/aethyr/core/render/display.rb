class Display
  def initialize socket
    @socket = socket
    @screen = Ncurses.newterm("vt100", socket, socket)
    
    Ncurses.set_term(@screen)
    Ncurses.resizeterm(25, 80)
    Ncurses.cbreak           # provide unbuffered input
    Ncurses.noecho           # turn off input echoing
    Ncurses.nonl             # turn off newline translation

    Ncurses.stdscr.intrflush(false) # turn off flush-on-interrupt
    Ncurses.stdscr.keypad(true)     # turn on keypad mode
    
    Ncurses.scrollok(Ncurses.stdscr, true)
    @window_main = Ncurses::WINDOW.new(0, 0, 0, 0)
    Ncurses.scrollok(@window_main, true)
  end
  
  def read_rdy?
    ready, _, _ = IO.select([@socket])
    ready.any?
  end
  
  def recv
    return nil unless read_rdy?
    Ncurses.stdscr.getch.to_s
  end
  
  def send (message, window_type: :main)
    window = nil
    case window_type
    when :main
      window = @window_main
    end
    raise "window_type not recognized" if window.nil?
    
    set_term

    window.printw message
    window.noutrefresh()
    Ncurses.doupdate()
  end
  
  def close
    set_term
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end
  
  private
  def set_term
    Ncurses.set_term(@screen)
  end
end