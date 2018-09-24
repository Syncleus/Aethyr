require 'aethyr/info/skills/skill'

module Skills
  class Kick < Skill
    @@ID = :kick
    def initialize(owner)
      super(owner, :kick, "Kick", "Kick your openent where it hurts.", :skill)
    end
  end
end
