require 'aethyr/gary'
require 'pp'

#Fairly small extensions to Gary. Used everywhere.
class Inventory < Gary
  attr_reader :capacity
  alias :size :length

  #Create new container with the given capacity. If capacity is nil or < 0, capacity is considered infinite.
  def initialize capacity = nil
    super()
    if capacity.nil? or capacity < 0
      @capacity = nil
    else
      @capacity = capacity
    end
    @grid = Hash.new
  end
  
    #Add an object to the container. Checks capacity first.
  def add( game_object, position = nil)
    unless position == nil
      return if @grid.has_key?(position) and @grid[position].eql? game_object
      raise "Slot is already full!" if @grid.has_key?(position)
      raise "Object already exists in another slot" if self.include?(game_object)
    end
    
    if @capacity.nil? or length < @capacity
      super game_object
    else
      raise "Inventory full!"
    end
    
    @grid[position] = game_object unless position == nil
  end
  
  def delete(game_object)
    super game_object
    @grid.delete_if{|_,v| v.eql? game_object}
  end
  
  def find_by_position(position)
    return nil if not @grid.has_key?(position)
    @grid[position]
  end
  
  def position game_object
    @grid.key game_object
  end

  def full?
    if @capacity.nil?
      false
    else
      @capacity - self.length != 0
    end
  end

  #Dump array of goids, ending with capacity.
  def marshal_dump
    inv = []
    each do |o|
      if o.is_a? GameObject
        inv << [o.game_object_id, position(o)]
      else
        inv << [o, position(o)]
      end
    end

    inv << @capacity
    

    return inv
  end

  #Set capacity and set inventory to a list of goids, then those get loaded.
  def marshal_load inv_capacity
    @mutex = Mutex.new
    unless inv_capacity.nil?
      @capacity = inv_capacity.pop
      #Okay, technically, it is not a hash at this point,
      #but an array of goids.
      #The StorageMachine creates a -new- Inventory and
      #loads the objects from this list of goids into
      #the new one, replaces this one with the new one
      #and everything goes from there.
      @ghash = inv_capacity
    end
  end

  def each &block
    if @ghash.is_a? Hash
      super &block
    else
      @ghash.dup.each do |goid|
        yield goid
      end
    end
  end

  #Returns nice listing of inventory.
  def show
    inv_out = []

    if empty?
      return "nothing"
    else
      self.each do |o|
        if o.name == ""
          name = o.generic
        else
          name = o.name
        end

        inv_out << "#{name}"
      end
    end

    return inv_out.list(self)
  end

  alias :remove :delete
  alias :shift :remove
  alias :<< :add
  alias :count :size

  def to_s
    @capacity ? cap = @capacity : cap = "infinity"
    "Inventory (#{self.count}/#{cap})"
  end
end
