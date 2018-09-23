require 'aethyr/info/terrain'

require 'aethyr/util/log'
require 'aethyr/objects/inventory'
require 'aethyr/traits/pronoun'
require 'aethyr/util/guid'
require 'observer'
require 'aethyr/info'

module Location
  def initialize(*args, terrain_type: nil, indoors: nil, swimming: nil)
    super
    if info.terrain.nil?
      info.terrain = Info.new
      info.terrain.indoors = indoors
      info.terrain.swimming = swimming
      info.terrain.type = terrain_type
    end
  end
  
  def area
    return self if self.is_a? Area
    self.parent_area
  end
  
  def parent_area
    return nil if $manager.nil?
    parent_id = @container
    until parent_id.nil? do
      parent = $manager.find(parent_id)
      return parent if parent.nil? or parent.is_a? Area
      parent_id = parent.container
    end
    nil
  end
  
  def flags
    collected_flags = self.parent_area.flags unless self.parent_area.nil?
    return info.flags.dup if collected_flags.nil?
    
    self.info.flags.values.each do |f|
      f.negate_flags(collected_flags)
    end
    collected_flags.merge! self.info.flags
  end
  
  def terrain_type
    return info.terrain.type unless info.terrain.type.nil?
    return self.parent_area.terrain_type unless self.parent_area.nil?
    nil
  end
end
