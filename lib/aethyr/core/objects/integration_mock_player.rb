class IntegrationMockPlayer
  attr_accessor :goid, :name, :container_goid, :info

  def initialize(goid, name = nil, container_goid = nil)
    @goid = goid
    @name = name || "Player #{goid}"
    @container_goid = container_goid
    @info = OpenStruct.new
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
    klass == Aethyr::Core::Objects::Player || super
  end
  
  # Add marshal_load method for deserialization
  def marshal_load(data)
    @goid = data[:goid] || data['goid']
    @name = data[:name] || data['name']
    @container_goid = data[:container_goid] || data['container_goid']
    @info = data[:info] || data['info'] || OpenStruct.new
    self
  end
  
  # Add marshal_dump method for serialization
  def marshal_dump
    {
      goid: @goid,
      name: @name,
      container_goid: @container_goid,
      info: @info
    }
  end

  def rehydrate(data)
    # Handle the case where data is nil
    return self if data.nil?
    
    # Handle both symbol and string keys for compatibility
    @goid = data[:goid] || data['goid'] || @goid
    @name = data[:name] || data['name'] || @name
    @container_goid = data[:container_goid] || data['container_goid'] || @container_goid
    @info = data[:info] || data['info'] || @info || OpenStruct.new
    self
  end
  
  # Add any other methods that might be needed for the mock player
  def output(message)
    # Mock implementation - does nothing in tests
  end
  
  def quit
    # Mock implementation - does nothing in tests
  end
end
