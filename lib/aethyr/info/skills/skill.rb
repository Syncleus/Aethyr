module Skills
  class Skill
    attr_reader :name, :help_desc, :type, :xp, :owner, :id

    def initialize(owner, id, name, help_desc, type = :trait, xp = 0)
      @id = id
      @name = name
      @help_desc = help_desc
      @type = type
      @xp = xp
      @owner = owner
    end

    def add_xp amount
      @xp += amount
    end

    def level
      (@xp / 10000) + 1
    end

    def xp_so_far
      @xp % 10000
    end

    def xp_to go
     10000 - xp_so_far
    end

    def level_percentage
      (xp_so_far.to_f / 10000.0) * 100.0
    end
  end
  
  class << self
    def skills(event, player, room)
      puts "skills called!"
    end
  end
end