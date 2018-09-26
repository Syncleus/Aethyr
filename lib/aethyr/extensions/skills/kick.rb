require 'aethyr/core/objects/info/skills/skill'

module Aethyr
  module Extensions
    module Skills
      class Kick < Aethyr::Skills::Skill
        def initialize(owner)
          super(owner, :kick, "Kick", "Kick your openent where it hurts.", :skill)
        end
      end
    end
  end
end