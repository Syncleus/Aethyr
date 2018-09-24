require 'aethyr/core/objects/game_object'
require 'aethyr/core/objects/traits/has_inventory'

#Container is used extensively inside the codebase, though essentially it is just a GameObject
#with an Inventory that propogates commands to its contents.
class Container < GameObject
  include HasInventory

  #Create new container. Capacity is unlimited if unset.
  def initialize(capacity = nil, *args)
    super(*args)

    @generic = "container"
    @inventory = Inventory.new(capacity)
  end

  #Add an object to the container.
  def add(object)
    @inventory << object
    object.container = @game_object_id
  end

  #Propagates alert to all in the container.
  def alert(event)
    @inventory.each do |o|
      o.alert(event)
    end
  end

  #Remove object from room.
  def remove(object)
    @inventory.remove(object)
    object.container = nil
  end

  #Find a GameObject with that name in the container. Returns the GameObject if found, else nil. Actually just calls Inventory#find
  def find(object_name, type = nil)
    @inventory.find(object_name, type = nil)
  end

  #Checks if the container contains the given id.
  def include?(game_object_id)
    @inventory.include? game_object_id
  end

  #Outputs message to all in container, except those listed in skip.
  def output(message, *skip)
    skip = Set.new(skip)

    @inventory.each do |o|
      o.output(message) unless skip.include?(o)
    end
  end

  #Sends an event out to contents.
  def out_event(event, *skip)
    skip = Set.new(skip)

    if event[:to_player] and event[:player] and @inventory.include? event[:player].goid
      event[:player].out_event(event)
      skip << event[:player]
    end

    if event[:to_target] and event[:target] and @inventory.include? event[:target].goid
      event[:target].out_event(event)
      skip << event[:target]
    end

    self.alert event if self.is_a? Reacts and not skip.include? self

    @inventory.each do |o|
      o.out_event(event) unless skip.include?(o)
    end
  end

  #Returns a String describing contents.
  def look_inside(event)
    event[:player].output("#{self.name} contains:\n" << @inventory.show)
  end
end

class GridContainer < Container
  def add(object, position = nil)
    @inventory.add(object, position)
    object.container = @game_object_id
  end
  
  def find_by_position(position)
    @inventory.find_by_position(position)
  end
  
  def position game_object
    @inventory.position(game_object)
  end
end