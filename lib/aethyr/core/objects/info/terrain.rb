module Terrain
  class Terrain
    attr_reader :room_text, :area_text, :name, :flags

    def initialize(name, room_text, area_text, flags = nil)
      @name = name
      @room_text = room_text
      @area_text = area_text
      @flags = Set.new flags
    end
  end

  GRASSLAND = Terrain.new("grasslands", "part of the grasslands", "waving grasslands")
  UNDERGROUND = Terrain.new("underground", "an underground cavern", "underground caverns")
  CITY = Terrain.new("city", "a city", "city streets")
  TOWN = Terrain.new("town", "a town", "small town roads")
  TUNDRA = Terrain.new("tundra", "a snowy plain", "icy plains")
end