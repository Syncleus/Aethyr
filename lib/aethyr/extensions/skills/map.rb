require 'aethyr/core/objects/info/skills/skill'

module Skills
  class Map < Skill
    @@ID = :map
    def initialize(owner)
      super(owner, :map, "Map", "Maps the layout and contents of an area", :skill)
    end
  end
end