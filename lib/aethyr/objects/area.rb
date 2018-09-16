require 'aethyr/objects/container'
require 'aethyr/objects/inventory_grid'

#An Area contains rooms and can be used to manage the weather and other area-wide information.
#Right now they don't do much but hold rooms, though.
#
#==Info
# info.terrain = Info.new
# info.terrain.area_type = :urban
class Area < Container

  def initialize(*args)
    super
    info.terrain = Info.new
    info.terrain.area_type = :urban
    @article = "an"
    @generic = "area"
  end

  #Returns self.
  def area
    self
  end
end

class MappableArea < Area
  attr_accessor :map_type
  
  def initialize(*args)
    super
    @map_type = :rooms
  end
  
  def add(object)
    raise "Must add game objects with coordinates!"
  end
  
  def add(object, x, y)
    @inventory.add(object, x, y)
    object.container = @game_object_id
  end
  
  protected
  def init_inventory capacity = nil
    @inventory = InventoryGrid.new(capacity)
  end
end