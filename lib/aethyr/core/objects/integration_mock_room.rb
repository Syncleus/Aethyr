class IntegrationMockRoom
  attr_accessor :goid, :name, :coordinates, :container_goid

  def initialize(goid, name = nil, coordinates = nil, container_goid = nil)
    @goid = goid
    @name = name || "Room #{goid}"
    @coordinates = coordinates || [0, 0]
    @container_goid = container_goid || "world_area"
  end

  def game_object_id
    @goid
  end

  def admin
    false
  end

  def room
    @container_goid
  end

  def container
    @container_goid
  end

  def is_a?(klass)
    klass == Aethyr::Core::Objects::Room || super
  end
  
  # Add marshal_load method for deserialization
  def marshal_load(data)
    @goid = data[:goid] || data['goid']
    @name = data[:name] || data['name']
    @coordinates = data[:coordinates] || data['coordinates'] || [0, 0]
    @container_goid = data[:container_goid] || data['container_goid'] || "world_area"
    self
  end
  
  # Add marshal_dump method for serialization
  def marshal_dump
    {
      goid: @goid,
      name: @name,
      coordinates: @coordinates,
      container_goid: @container_goid
    }
  end

  def rehydrate(data)
    # Handle the case where data is nil
    return self if data.nil?
    
    # Handle both symbol and string keys for compatibility
    @goid = data[:goid] || data['goid'] || @goid
    @name = data[:name] || data['name'] || @name
    @coordinates = data[:coordinates] || data['coordinates'] || @coordinates || [0, 0]
    @container_goid = data[:container_goid] || data['container_goid'] || @container_goid || "world_area"
    self
  end
end
