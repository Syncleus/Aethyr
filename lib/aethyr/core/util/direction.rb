module Aethyr
  module Direction
    #Returns the opposite direction. If no direction matches, returns dir.
    #
    # opposite_dir "west" => "east"
    # opposite_dir "u" => "down"
    # opposite_dir "around" => "around"
    def opposite_dir dir

      return dir unless dir.is_a? String

      case dir.downcase
      when "e", "east"
        "west"
      when "w", "west"
        "east"
      when "n", "north"
        "south"
      when "s", "south"
        "north"
      when "ne", "northeast"
        "southwest"
      when "se", "southeast"
        "northwest"
      when "sw", "southwest"
        "northeast"
      when "nw", "northwest"
        "southeast"
      when "up"
        "down"
      when "down"
        "up"
      when "in"
        "out"
      when "out"
        "in"
      else
        dir
      end
    end

    def expand_direction dir

      return dir unless dir.is_a? String

      case dir.downcase
      when "e", "east"
        "east"
      when "w", "west"
        "west"
      when "n", "north"
        "north"
      when "s", "south"
        "south"
      when "ne", "northeast"
        "northeast"
      when "se", "southeast"
        "southeast"
      when "sw", "southwest"
        "southwest"
      when "nw", "northwest"
        "northwest"
      when "u", "up"
        "up"
      when "d", "down"
        "down"
      when "i", "in"
        "in"
      when "o", "out"
        "out"
      else
        dir
      end
    end
  end
end