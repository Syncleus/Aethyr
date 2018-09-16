require 'aethyr/objects/inventory'

class InventoryGrid < Inventory
  def initialize(*args)
    super
    @grid = Hash.new
  end
  
  #Add an object to the container. Checks capacity first.
  def add game_object
      raise "Must add game objects with coordinates!"
  end
  
  def add( game_object, x, y)
    return if @grid.has_key?([x,y]) and @grid[[x,y]].eql? game_object
    raise "Slot is already full!" if @grid.has_key?([x,y])
    raise "Object already exists in another slot" if self.include?(game_object)
    Inventory.instance_method(:add).bind(self).call(game_object)
    @grid[[x,y]] = game_object
  end
  
  def delete game_object
    super game_object
    @grid.delete_if{|_,v| v.eql? game_object}
  end
  
  def find_by_cords(x, y)
    return nil if not @grid.has_key?([x,y])
    @grid[[x,y]]
  end
end