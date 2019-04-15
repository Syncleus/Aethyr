#ANSI colors.
module Color
  module Formatting
    @@attributes = [
    [ :bold, "\e[1m"],
    [ :dim, "\e[2m"],
    [ :underlined, "\e[4m"],
    [ :blink, "\e[5m"],
    [ :reverse, "\e[7m"]
    ]

    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end

    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end

    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end

  module Reset
    @@attributes = [
    [ :all, "\e[0m"],
    [ :bold, "\e[21m"],
    [ :dim, "\e[22m"],
    [ :underlined, "\e[24m"],
    [ :blink, "\e[25m"],
    [ :reverse, "\e[27m"]
    ]

    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end

    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end

    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end

  module Foreground
    @@attributes = [
      [ :gray, 0],
      [ :red, 1],
      [ :green, 2],
      [ :yellow, 3],
      [ :blue, 4],
      [ :magenta, 5],
      [ :cyan, 6],
      [ :white, 7],
      [ :light_gray, 8],
      [ :bright_red, 9],
      [ :bright_green, 10],
      [ :bright_yellow, 11],
      [ :bright_blue, 12],
      [ :bright_magenta, 13],
      [ :bright_cyan, 14],
      [ :bright_white, 15],
      [ :black, 16],
    ]
    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end

    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end

    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end

  module Background
    @@attributes = [
      [ :gray, 0],
      [ :red, 1],
      [ :green, 2],
      [ :yellow, 3],
      [ :blue, 4],
      [ :magenta, 5],
      [ :cyan, 6],
      [ :white, 7],
      [ :light_gray, 8],
      [ :bright_red, 9],
      [ :bright_green, 10],
      [ :bright_yellow, 11],
      [ :bright_blue, 12],
      [ :bright_magenta, 13],
      [ :bright_cyan, 14],
      [ :bright_white, 15],
      [ :black, 16],
    ]

    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end

    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end

    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end
end

class FormatState
  attr_reader :parent

  def initialize(activate_color, parent = nil, fg: nil, bg: nil, blink: nil, dim: nil, underline: nil, bold: nil, reverse: nil, standout: nil)
    @activate_color = activate_color
    @parent = parent

    if fg.is_a? String
      if fg.scan(/\D/).empty?
        @fg = fg.to_i
      else
        @fg = Color::Foreground.attribute(fg.to_sym)
      end
    else
      @fg = fg
    end

    if bg.is_a? String
      if bg.scan(/\D/).empty?
        @bg = bg.to_i
      else
        @bg = Color::Foreground.attribute(bg.to_sym)
      end
    else
      @bg = bg
    end

    @blink = blink
    @dim = dim
    @underline = underline
    @bold = bold
    @reverse = reverse
    @standout = standout
  end

  def initialize(code, activate_color, parent = nil)
    @activate_color = activate_color
    @parent = parent
    code_working = code.dup

    code_working.gsub!(/\s\s*/i) do |match|
      " "
    end

    fg_text = code_working[/fg\:([a-zA-Z0-9\_]*)\s*/i, 1].dup
    code_working.gsub!(/fg\:([a-zA-Z0-9\_]*)\s*/i) do |match|
      ""
    end

    bg_text = code_working[/bg\:([a-zA-Z0-9\_]*)\s*/i, 1].dup
    code_working.gsub!(/bg\:([a-zA-Z0-9\_]*)\s*/i) do |match|
      ""
    end

    formatting_text = code.strip.split(' ')

    unless fg_text.nil?
      if fg_text.scan(/\D/).empty?
        @fg = fg_text.to_i
      else
        @fg = Color::Foreground.attribute(fg_text.to_sym)
      end
    end

    unless bg_text.nil?
      if bg_text.scan(/\D/).empty?
        @bg = bg_text.to_i
      else
        @bg = Color::Foreground.attribute(bg_text.to_sym)
      end
    end

    formatting_text.each do |format|
      case format
      when "blink"
        @blink = true
      when "noblink"
        @blink = false
      when "dim"
        @dim = true
      when "nodim"
        @dim = false
      when "underline"
        @underline = true
      when "nounderline"
        @underline = false
      when "bold"
        @bold = true
      when "nobold"
        @bold = false
      when "reverse"
        @reverse = true
      when "noreverse"
        @reverse = false
      when "standout"
        @standout = true
      when "nostandout"
        @standout = false
      end
    end
  end

  def fg
    return @fg unless @fg.nil?
    return @parent.fg unless @parent.nil?
    Color::Foreground.attribute(:white)
  end

  def bg
    return @bg unless @bg.nil?
    return @parent.bg unless @parent.nil?
    Color::Background.attribute(:black)
  end

  def blink?
    return @blink unless @blink.nil?
    return @parent.blink? unless @parent.nil?
    false
  end

  def dim?
    return @dim unless @dim.nil?
    return @parent.dim? unless @parent.nil?
    false
  end

  def bold?
    return @bold unless @bold.nil?
    return @parent.bold? unless @parent.nil?
    false
  end

  def underline?
    return @underline unless @underline.nil?
    return @parent.underline? unless @parent.nil?
    false
  end

  def reverse?
    return @reverse unless @reversed.nil?
    return @parent.reverse? unless @parent.nil?
    false
  end

  def standout?
    return @standout unless @standout.nil?
    return @parent.standout? unless @parent.nil?
    false
  end

  def apply(window)
    @activate_color.call(window, self.fg, self.bg)

    if blink?
      window.attron(Ncurses::A_BLINK)
    else
      window.attroff(Ncurses::A_BLINK)
    end

    if dim?
      window.attron(Ncurses::A_DIM)
    else
      window.attroff(Ncurses::A_DIM)
    end

    if bold?
      window.attron(Ncurses::A_BOLD)
    else
      window.attroff(Ncurses::A_BOLD)
    end

    if underline?
      window.attron(Ncurses::A_UNDERLINE)
    else
      window.attroff(Ncurses::A_UNDERLINE)
    end

    if reverse?
      window.attron(Ncurses::A_REVERSE)
    else
      window.attroff(Ncurses::A_REVERSE)
    end

    if standout?
      window.attron(Ncurses::A_STANDOUT)
    else
      window.attroff(Ncurses::A_STANDOUT)
    end
  end

  def revert(window)
    return @parent.apply(window) unless @parent.nil?

    @activate_color.call(window, Color::Foreground.attribute(:white), Color::Background.attribute(:black))
    window.attrset(Ncurses::A_NORMAL)
  end
end
