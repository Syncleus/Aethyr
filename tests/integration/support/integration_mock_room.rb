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
end
