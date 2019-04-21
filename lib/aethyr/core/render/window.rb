require "ncursesw"

class Window
  attr_reader :window_border, :window_text, :buffer, :buffer_lines, :text_height, :text_width, :x, :y, :height, :width, :buffered, :use_color, :buffer_size, :color_settings, :buffer_pos
  attr_accessor :selected

  def initialize( color_settings, buffered: false, buffer_size: 10000 )
    @buffer = [] if buffered
    @buffer_lines = [] if buffered
    @buffer_pos = 0 if buffered
    @buffer_size = buffer_size if buffered
    @buffered = buffered
    @selected = false
    @use_color = false
    @color_settings = color_settings
    @color_stack = []
    @exists = false
  end

  def exists?
    return @exists
  end

  def create(width: 0, height: 0, x: 0, y: 0)
    raise "width out of range" unless width >= 0
    raise "height out of range" unless height >= 0
    raise "x out of range" unless x >= 0
    raise "y out of range" unless y >= 0
    @height = height
    @width = width
    @x = x
    @y = y

    destroy
    @exists = true
    @window_border = Ncurses::WINDOW.new(@height, @width, @y, @x)
    @window_border_height = @window_border.getmaxy - 2
    @window_border_width = @window_border.getmaxx - 2
    @window_text = @window_border.derwin(@window_border_height, @window_border_width, 1, 1)
    @text_height = @window_text.getmaxy - 2
    @text_width = @window_text.getmaxx - 2
    Ncurses.scrollok(@window_text, true)
    @window_text.clear
    @window_text.move(@text_height, 1)

    if buffered
      @buffer_pos = 0 if @buffered
      parse_buffer
      buffer_from = [@buffer_lines.length * -1, -1 * (@height + @buffer_pos + 1)].max
      buffer_to = [@buffer_lines.length * -1, (@buffer_pos + 1) * -1].max

      @buffer_lines[buffer_from..buffer_to].each do | message|
        render(message)
      end
    end
  end

  def destroy
    @exists = false
    Ncurses.delwin(@window_border) unless @window_border.nil?
    @window_border = nil
    @window_text = nil
    @selected = false
  end

  def update
    white_fg = Color::Foreground.attribute(:white)
    grey_fg = Color::Foreground.attribute(:grey)
    black_bg = Color::Background.attribute(:black)

    if @use_color
      activate_color_window(@window_border, grey_fg, black_bg) unless @window_border.nil?
    end

    default_border = 32
    @window_border.border(*([default_border]*8)) unless @window_border.nil?

    if @use_color
      activate_color_window(@window_border, white_fg, black_bg) if @selected && @window_border.nil? == false
    end

    @window_border.border(*([0]*8)) if @selected && @window_border.nil? == false

    @window_border.noutrefresh() unless @window_border.nil?
    @window_text.noutrefresh() unless @window_text.nil?
  end

  def enable_color
    @use_color = true
  end

  def activate_color(fg, bg)
    activate_color_window(@window_text, fg, bg)
  end

  def clear
    @window_text.clear
  end

  def send (message, word_wrap = true, add_newline: true)
    unless @buffer.nil?
      @buffer << message.dup
      @buffer << "" if add_newline
      @buffer.drop(@buffer.length - @buffer_size) if @buffer.length > @buffer_size
    end

    message = message.tr("\r", '')
    if buffered
      render_buffer
    else
      render(message, add_newline: add_newline)
    end
  end

  def buffer_pos= new_pos
    @buffer_pos = new_pos if new_pos <= @buffer_size && new_pos <= @buffer_lines.length - @text_height && new_pos >= 0
    render_buffer
  end

  def self.split_message(message, cols = @text_width)
    new_message = message.gsub(/\t/, '     ')
    new_message.tr!("\r", '')

    last_was_text = false
    buffer_lines = []
    new_message.split(/(\n)/) do |line|
      next if line.nil? || line.length == 0
      if line.length == 1 && line.start_with?("\n")
        if last_was_text
          last_was_text = false
        else
          buffer_lines << ""
        end
      else
        buffer_lines.concat(word_wrap(line, cols))
        last_was_text = true
      end
    end
    return buffer_lines
  end

  def self.word_wrap(line, cols = @text_width)
    lines = []
    new_line = ""
    new_line_length = 0
    next_line = ""
    next_line_length = 0
    inside_tag = false
    line.each_char do |c|
      if c =~ /\S/
        next_line += c
        if c == "<"
          inside_tag = true
        elsif c == ">"
          inside_tag = false
        elsif inside_tag == false
          next_line_length += 1
        end

        if next_line_length + new_line_length >= cols
          if new_line_length == 0
            lines << new_line + next_line
            next_line = ""
            new_line = ""
            next_line_length = 0
          else
            lines << new_line
            new_line = ""
            new_line_length = 0
          end
        end
      elsif next_line.length == 0
        new_line += c
        new_line_length += 1 unless inside_tag
      else
        if next_line_length + new_line_length >= cols
          lines << (new_line + next_line + c)
          new_line = ""
          new_line_length = 0
          next_line = ""
          next_line_length = 0
        else
          new_line += next_line + c
          new_line_length += next_line_length
          new_line_length += 1 unless inside_tag
          next_line = ""
          next_line_length = 0
        end
      end
    end
    lines << new_line + next_line if new_line.length > 0 || next_line.length > 0
    return lines
  end

  private
  def activate_color_window(window, fg, bg)
    return if not @use_color
    #window.attron(fg + bg * Ncurses.COLORS)
    if Ncurses.respond_to?(:color_set)
      window.color_set(fg + bg * Ncurses.COLORS, nil)
    else
      window.attrset(Ncurses.COLOR_PAIR(fg + bg * Ncurses.COLORS))
    end
  end

  def render_buffer
    parse_buffer
    buffer_from = [@buffer_lines.length * -1, -1 * (@text_height + @buffer_pos + 1)].max
    buffer_to = [@buffer_lines.length * -1, (@buffer_pos + 1) * -1].max

    @window_text.move(0,0)
    @buffer_lines[buffer_from..buffer_to].each do | message|
      colored_send(message + "\n")
    end
  end

  def render(message, add_newline: true)
    message += "\n" if add_newline
    colored_send(message)
  end

  def colored_send(message)
    regular_format = nil
    if @use_color
      regular_format = FormatState.new(@color_settings["regular"], self.method(:activate_color))
      regular_format.apply(@window_text)
    end

    colors = @color_settings.keys.dup
    colors << "raw[^>]*"
    colors = colors.join("|")

    message.split(/(<[\/]{0,1}[^>]*>)/i).each do |part|
      if part.start_with? "<"
        if @use_color
          part.match(/<([\/]{0,1})([^>]*)>/i) do
            if ($1.nil?) || ($1.length <= 0)
              color_encode($2)
            else
              color_decode($2)
            end
          end
        end
      else
        @window_text.addstr("#{part}")
      end
    end

    if @use_color
      regular_format.revert(@window_text)
    end

    update
  end

  def color_encode(code)
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
    result.apply(@window_text)
  end

  def color_decode(code)
    @color_stack.pop.revert(@window_text)
  end

  def parse_buffer(cols = @text_width)
    raise "channel has no buffer" if buffer.nil?
    @buffer_lines  = []

    @buffer.each do |message|
      @buffer_lines.concat(Window.split_message(message, cols))
    end
  end
end
