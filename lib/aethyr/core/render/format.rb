#ANSI colors.
module Color

  module Foreground
    @@attributes = [
      [ :grey0, 0],
      [ :maroon, 1],
      [ :green, 2],
      [ :olive, 3],
      [ :navy, 4],
      [ :purple, 5],
      [ :teal, 6],
      [ :silver, 7],
      [ :grey, 8],
      [ :red, 9],
      [ :lime, 10],
      [ :yellow, 11],
      [ :blue, 12],
      [ :fuchsia, 13],
      [ :aqua, 14],
      [ :white, 15],
      [ :black, 16],
      [ :navyblue, 17],
      [ :darkblue, 18],
      [ :blue3, 19],
      [ :blue3, 20],
      [ :blue1, 21],
      [ :darkgreen, 22],
      [ :deepskyblue4, 23],
      [ :deepskyblue4, 24],
      [ :deepskyblue4, 25],
      [ :dodgerblue3, 26],
      [ :dodgerblue2, 27],
      [ :green4, 28],
      [ :springgreen4, 29],
      [ :turquoise4, 30],
      [ :deepskyblue3, 31],
      [ :deepskyblue3, 32],
      [ :dodgerblue1, 33],
      [ :green3, 34],
      [ :springgreen3, 35],
      [ :darkcyan, 36],
      [ :lightseagreen, 37],
      [ :deepskyblue2, 38],
      [ :deepskyblue1, 39],
      [ :green3, 40],
      [ :springgreen3, 41],
      [ :springgreen2, 42],
      [ :cyan3, 43],
      [ :darkturquoise, 44],
      [ :turquoise2, 45],
      [ :green1, 46],
      [ :springgreen2, 47],
      [ :springgreen1, 48],
      [ :mediumspringgreen, 49],
      [ :cyan2, 50],
      [ :cyan1, 51],
      [ :cyan, 51],
      [ :darkred, 52],
      [ :deeppink4, 53],
      [ :purple4, 54],
      [ :purple4, 55],
      [ :purple3, 56],
      [ :blueviolet, 57],
      [ :orange4, 58],
      [ :grey37, 59],
      [ :mediumpurple4, 60],
      [ :slateblue3, 61],
      [ :slateblue3, 62],
      [ :royalblue1, 63],
      [ :chartreuse4, 64],
      [ :darkseagreen4, 65],
      [ :paleturquoise4, 66],
      [ :steelblue, 67],
      [ :steelblue3, 68],
      [ :cornflowerblue, 69],
      [ :chartreuse3, 70],
      [ :darkseagreen4, 71],
      [ :cadetblue, 72],
      [ :cadetblue, 73],
      [ :skyblue3, 74],
      [ :steelblue1, 75],
      [ :chartreuse3, 76],
      [ :palegreen3, 77],
      [ :seagreen3, 78],
      [ :aquamarine3, 79],
      [ :mediumturquoise, 80],
      [ :steelblue1, 81],
      [ :chartreuse2, 82],
      [ :seagreen2, 83],
      [ :seagreen1, 84],
      [ :seagreen1, 85],
      [ :aquamarine1, 86],
      [ :darkslategray2, 87],
      [ :darkred, 88],
      [ :deeppink4, 89],
      [ :darkmagenta, 90],
      [ :darkmagenta, 91],
      [ :darkviolet, 92],
      [ :purple, 93],
      [ :orange4, 94],
      [ :lightpink4, 95],
      [ :plum4, 96],
      [ :mediumpurple3, 97],
      [ :mediumpurple3, 98],
      [ :slateblue1, 99],
      [ :yellow4, 100],
      [ :wheat4, 101],
      [ :grey53, 102],
      [ :lightslategrey, 103],
      [ :mediumpurple, 104],
      [ :lightslateblue, 105],
      [ :yellow4, 106],
      [ :darkolivegreen3, 107],
      [ :darkseagreen, 108],
      [ :lightskyblue3, 109],
      [ :lightskyblue3, 110],
      [ :skyblue2, 111],
      [ :chartreuse2, 112],
      [ :darkolivegreen3, 113],
      [ :palegreen3, 114],
      [ :darkseagreen3, 115],
      [ :darkslategray3, 116],
      [ :skyblue1, 117],
      [ :chartreuse1, 118],
      [ :lightgreen, 119],
      [ :lightgreen, 120],
      [ :palegreen1, 121],
      [ :aquamarine1, 122],
      [ :darkslategray1, 123],
      [ :red3, 124],
      [ :deeppink4, 125],
      [ :mediumvioletred, 126],
      [ :magenta3, 127],
      [ :darkviolet, 128],
      [ :purple, 129],
      [ :darkorange3, 130],
      [ :indianred, 131],
      [ :hotpink3, 132],
      [ :mediumorchid3, 133],
      [ :mediumorchid, 134],
      [ :mediumpurple2, 135],
      [ :darkgoldenrod, 136],
      [ :lightsalmon3, 137],
      [ :rosybrown, 138],
      [ :grey63, 139],
      [ :mediumpurple2, 140],
      [ :mediumpurple1, 141],
      [ :gold3, 142],
      [ :darkkhaki, 143],
      [ :navajowhite3, 144],
      [ :grey69, 145],
      [ :lightsteelblue3, 146],
      [ :lightsteelblue, 147],
      [ :yellow3, 148],
      [ :darkolivegreen3, 149],
      [ :darkseagreen3, 150],
      [ :darkseagreen2, 151],
      [ :lightcyan3, 152],
      [ :lightskyblue1, 153],
      [ :greenyellow, 154],
      [ :darkolivegreen2, 155],
      [ :palegreen1, 156],
      [ :darkseagreen2, 157],
      [ :darkseagreen1, 158],
      [ :paleturquoise1, 159],
      [ :red3, 160],
      [ :deeppink3, 161],
      [ :deeppink3, 162],
      [ :magenta3, 163],
      [ :magenta3, 164],
      [ :magenta2, 165],
      [ :darkorange3, 166],
      [ :indianred, 167],
      [ :hotpink3, 168],
      [ :hotpink2, 169],
      [ :orchid, 170],
      [ :mediumorchid1, 171],
      [ :orange3, 172],
      [ :lightsalmon3, 173],
      [ :lightpink3, 174],
      [ :pink3, 175],
      [ :plum3, 176],
      [ :violet, 177],
      [ :gold3, 178],
      [ :lightgoldenrod3, 179],
      [ :tan, 180],
      [ :mistyrose3, 181],
      [ :thistle3, 182],
      [ :plum2, 183],
      [ :yellow3, 184],
      [ :khaki3, 185],
      [ :lightgoldenrod2, 186],
      [ :lightyellow3, 187],
      [ :grey84, 188],
      [ :lightsteelblue1, 189],
      [ :yellow2, 190],
      [ :darkolivegreen1, 191],
      [ :darkolivegreen1, 192],
      [ :darkseagreen1, 193],
      [ :honeydew2, 194],
      [ :lightcyan1, 195],
      [ :red1, 196],
      [ :deeppink2, 197],
      [ :deeppink1, 198],
      [ :deeppink1, 199],
      [ :magenta2, 200],
      [ :magenta1, 201],
      [ :orangered1, 202],
      [ :indianred1, 203],
      [ :indianred1, 204],
      [ :hotpink, 205],
      [ :hotpink, 206],
      [ :mediumorchid1, 207],
      [ :darkorange, 208],
      [ :salmon1, 209],
      [ :lightcoral, 210],
      [ :palevioletred1, 211],
      [ :orchid2, 212],
      [ :orchid1, 213],
      [ :orange1, 214],
      [ :sandybrown, 215],
      [ :lightsalmon1, 216],
      [ :lightpink1, 217],
      [ :pink1, 218],
      [ :plum1, 219],
      [ :gold1, 220],
      [ :lightgoldenrod2, 221],
      [ :lightgoldenrod2, 222],
      [ :navajowhite1, 223],
      [ :mistyrose1, 224],
      [ :thistle1, 225],
      [ :yellow1, 226],
      [ :lightgoldenrod1, 227],
      [ :khaki1, 228],
      [ :wheat1, 229],
      [ :cornsilk1, 230],
      [ :grey100, 231],
      [ :grey3, 232],
      [ :grey7, 233],
      [ :grey11, 234],
      [ :grey15, 235],
      [ :grey19, 236],
      [ :grey23, 237],
      [ :grey27, 238],
      [ :grey30, 239],
      [ :grey35, 240],
      [ :grey39, 241],
      [ :grey42, 242],
      [ :grey46, 243],
      [ :grey50, 244],
      [ :grey54, 245],
      [ :grey58, 246],
      [ :grey62, 247],
      [ :grey66, 248],
      [ :grey70, 249],
      [ :grey74, 250],
      [ :grey78, 251],
      [ :grey82, 252],
      [ :grey85, 253],
      [ :grey89, 254],
      [ :grey93, 255],
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
      [ :grey0, 0],
      [ :maroon, 1],
      [ :green, 2],
      [ :olive, 3],
      [ :navy, 4],
      [ :purple, 5],
      [ :teal, 6],
      [ :silver, 7],
      [ :grey, 8],
      [ :red, 9],
      [ :lime, 10],
      [ :yellow, 11],
      [ :blue, 12],
      [ :fuchsia, 13],
      [ :aqua, 14],
      [ :white, 15],
      [ :black, 16],
      [ :navyblue, 17],
      [ :darkblue, 18],
      [ :blue3, 19],
      [ :blue3, 20],
      [ :blue1, 21],
      [ :darkgreen, 22],
      [ :deepskyblue4, 23],
      [ :deepskyblue4, 24],
      [ :deepskyblue4, 25],
      [ :dodgerblue3, 26],
      [ :dodgerblue2, 27],
      [ :green4, 28],
      [ :springgreen4, 29],
      [ :turquoise4, 30],
      [ :deepskyblue3, 31],
      [ :deepskyblue3, 32],
      [ :dodgerblue1, 33],
      [ :green3, 34],
      [ :springgreen3, 35],
      [ :darkcyan, 36],
      [ :lightseagreen, 37],
      [ :deepskyblue2, 38],
      [ :deepskyblue1, 39],
      [ :green3, 40],
      [ :springgreen3, 41],
      [ :springgreen2, 42],
      [ :cyan3, 43],
      [ :darkturquoise, 44],
      [ :turquoise2, 45],
      [ :green1, 46],
      [ :springgreen2, 47],
      [ :springgreen1, 48],
      [ :mediumspringgreen, 49],
      [ :cyan2, 50],
      [ :cyan1, 51],
      [ :cyan, 51],
      [ :darkred, 52],
      [ :deeppink4, 53],
      [ :purple4, 54],
      [ :purple4, 55],
      [ :purple3, 56],
      [ :blueviolet, 57],
      [ :orange4, 58],
      [ :grey37, 59],
      [ :mediumpurple4, 60],
      [ :slateblue3, 61],
      [ :slateblue3, 62],
      [ :royalblue1, 63],
      [ :chartreuse4, 64],
      [ :darkseagreen4, 65],
      [ :paleturquoise4, 66],
      [ :steelblue, 67],
      [ :steelblue3, 68],
      [ :cornflowerblue, 69],
      [ :chartreuse3, 70],
      [ :darkseagreen4, 71],
      [ :cadetblue, 72],
      [ :cadetblue, 73],
      [ :skyblue3, 74],
      [ :steelblue1, 75],
      [ :chartreuse3, 76],
      [ :palegreen3, 77],
      [ :seagreen3, 78],
      [ :aquamarine3, 79],
      [ :mediumturquoise, 80],
      [ :steelblue1, 81],
      [ :chartreuse2, 82],
      [ :seagreen2, 83],
      [ :seagreen1, 84],
      [ :seagreen1, 85],
      [ :aquamarine1, 86],
      [ :darkslategray2, 87],
      [ :darkred, 88],
      [ :deeppink4, 89],
      [ :darkmagenta, 90],
      [ :darkmagenta, 91],
      [ :darkviolet, 92],
      [ :purple, 93],
      [ :orange4, 94],
      [ :lightpink4, 95],
      [ :plum4, 96],
      [ :mediumpurple3, 97],
      [ :mediumpurple3, 98],
      [ :slateblue1, 99],
      [ :yellow4, 100],
      [ :wheat4, 101],
      [ :grey53, 102],
      [ :lightslategrey, 103],
      [ :mediumpurple, 104],
      [ :lightslateblue, 105],
      [ :yellow4, 106],
      [ :darkolivegreen3, 107],
      [ :darkseagreen, 108],
      [ :lightskyblue3, 109],
      [ :lightskyblue3, 110],
      [ :skyblue2, 111],
      [ :chartreuse2, 112],
      [ :darkolivegreen3, 113],
      [ :palegreen3, 114],
      [ :darkseagreen3, 115],
      [ :darkslategray3, 116],
      [ :skyblue1, 117],
      [ :chartreuse1, 118],
      [ :lightgreen, 119],
      [ :lightgreen, 120],
      [ :palegreen1, 121],
      [ :aquamarine1, 122],
      [ :darkslategray1, 123],
      [ :red3, 124],
      [ :deeppink4, 125],
      [ :mediumvioletred, 126],
      [ :magenta3, 127],
      [ :darkviolet, 128],
      [ :purple, 129],
      [ :darkorange3, 130],
      [ :indianred, 131],
      [ :hotpink3, 132],
      [ :mediumorchid3, 133],
      [ :mediumorchid, 134],
      [ :mediumpurple2, 135],
      [ :darkgoldenrod, 136],
      [ :lightsalmon3, 137],
      [ :rosybrown, 138],
      [ :grey63, 139],
      [ :mediumpurple2, 140],
      [ :mediumpurple1, 141],
      [ :gold3, 142],
      [ :darkkhaki, 143],
      [ :navajowhite3, 144],
      [ :grey69, 145],
      [ :lightsteelblue3, 146],
      [ :lightsteelblue, 147],
      [ :yellow3, 148],
      [ :darkolivegreen3, 149],
      [ :darkseagreen3, 150],
      [ :darkseagreen2, 151],
      [ :lightcyan3, 152],
      [ :lightskyblue1, 153],
      [ :greenyellow, 154],
      [ :darkolivegreen2, 155],
      [ :palegreen1, 156],
      [ :darkseagreen2, 157],
      [ :darkseagreen1, 158],
      [ :paleturquoise1, 159],
      [ :red3, 160],
      [ :deeppink3, 161],
      [ :deeppink3, 162],
      [ :magenta3, 163],
      [ :magenta3, 164],
      [ :magenta2, 165],
      [ :darkorange3, 166],
      [ :indianred, 167],
      [ :hotpink3, 168],
      [ :hotpink2, 169],
      [ :orchid, 170],
      [ :mediumorchid1, 171],
      [ :orange3, 172],
      [ :lightsalmon3, 173],
      [ :lightpink3, 174],
      [ :pink3, 175],
      [ :plum3, 176],
      [ :violet, 177],
      [ :gold3, 178],
      [ :lightgoldenrod3, 179],
      [ :tan, 180],
      [ :mistyrose3, 181],
      [ :thistle3, 182],
      [ :plum2, 183],
      [ :yellow3, 184],
      [ :khaki3, 185],
      [ :lightgoldenrod2, 186],
      [ :lightyellow3, 187],
      [ :grey84, 188],
      [ :lightsteelblue1, 189],
      [ :yellow2, 190],
      [ :darkolivegreen1, 191],
      [ :darkolivegreen1, 192],
      [ :darkseagreen1, 193],
      [ :honeydew2, 194],
      [ :lightcyan1, 195],
      [ :red1, 196],
      [ :deeppink2, 197],
      [ :deeppink1, 198],
      [ :deeppink1, 199],
      [ :magenta2, 200],
      [ :magenta1, 201],
      [ :orangered1, 202],
      [ :indianred1, 203],
      [ :indianred1, 204],
      [ :hotpink, 205],
      [ :hotpink, 206],
      [ :mediumorchid1, 207],
      [ :darkorange, 208],
      [ :salmon1, 209],
      [ :lightcoral, 210],
      [ :palevioletred1, 211],
      [ :orchid2, 212],
      [ :orchid1, 213],
      [ :orange1, 214],
      [ :sandybrown, 215],
      [ :lightsalmon1, 216],
      [ :lightpink1, 217],
      [ :pink1, 218],
      [ :plum1, 219],
      [ :gold1, 220],
      [ :lightgoldenrod2, 221],
      [ :lightgoldenrod2, 222],
      [ :navajowhite1, 223],
      [ :mistyrose1, 224],
      [ :thistle1, 225],
      [ :yellow1, 226],
      [ :lightgoldenrod1, 227],
      [ :khaki1, 228],
      [ :wheat1, 229],
      [ :cornsilk1, 230],
      [ :grey100, 231],
      [ :grey3, 232],
      [ :grey7, 233],
      [ :grey11, 234],
      [ :grey15, 235],
      [ :grey19, 236],
      [ :grey23, 237],
      [ :grey27, 238],
      [ :grey30, 239],
      [ :grey35, 240],
      [ :grey39, 241],
      [ :grey42, 242],
      [ :grey46, 243],
      [ :grey50, 244],
      [ :grey54, 245],
      [ :grey58, 246],
      [ :grey62, 247],
      [ :grey66, 248],
      [ :grey70, 249],
      [ :grey74, 250],
      [ :grey78, 251],
      [ :grey82, 252],
      [ :grey85, 253],
      [ :grey89, 254],
      [ :grey93, 255],
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
