require 'aethyr/info/flags/flag'

class PlusWater < Flag
  def initialize(affected)
    super(affected, :plus_water, "+water", "Everything around you is <waterhigh>humid</waterhigh> and <waterhigh>wet</waterhigh>.", "Indicates the objects is strong in elemental water energy.", [:minus_water])
  end
end

class MinusWater < Flag
  def initialize(affected)
    super(affected, :minus_water, "-water", "It is <waterlow>dry</waterlow> and <waterlow>arid</waterlow>.", "Indicates the objects is lacking in elemental water energy.", [:plus_water])
  end
end

class PlusEarth < Flag
  def initialize(affected)
    super(affected, :plus_earth, "+earth", "The earth is <earthhigh>alive</earthhigh> and <earthhigh>growing</earthhigh>.", "Indicates the objects is strong in elemental earth energy.", [:minus_earth])
  end
end

class MinusEarth < Flag
  def initialize(affected)
    super(affected, :minus_earth, "-earth", "The earth lies <earthlow>barren</earthlow>, covered in <earthlow>dust</earthlow>.", "Indicates the objects is lacking in elemental earth energy.", [:plus_earth])
  end
end

class PlusFire < Flag
  def initialize(affected)
    super(affected, :plus_fire, "+fire", "It is so <firehigh>hot</firehigh> it is <firehigh>hard to breathe</firehigh>.", "Indicates the objects is strong in elemental fire energy.", [:minus_fire])
  end
end

class MinusFire < Flag
  def initialize(affected)
    super(affected, :minus_fire, "-fire", "It is <firelow>deathly cold</firelow>, your <firelow>breath freezes</firelow> as you exhale.", "Indicates the objects is lacking in elemental fire energy.", [:plus_fire])
  end
end

class PlusAir < Flag
  def initialize(affected)
    super(affected, :plus_air, "+air", "The air is <airhigh>fresh</airhigh> with an <airhigh>inviting breeze</airhigh>.", "Indicates the objects is strong in elemental air energy.", [:minus_air])
  end
end

class MinusAir < Flag
  def initialize(affected)
    super(affected, :minus_air, "-air", "The air is <airlow>stale</airlow> and <airlow>stagnant</airlow>.", "Indicates the objects is lacking in elemental air energy.", [:plus_air])
  end
end