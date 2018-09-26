require 'aethyr/core/objects/info/skills/skill'

module Aethyr
  module Extensions
    module Skills
      class Map < Aethyr::Skills::Skill
        def initialize(owner)
          super(owner, :map, "Map", "Maps the layout and contents of an area", :skill)
        end
      end
    end
  end
end