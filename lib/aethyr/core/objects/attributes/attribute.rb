class Attribute

  attr_reader :attached_to

  def initialize(attach_to)
    if not attach_to.is_a? GameObject
      raise ArgumentError.new "Can only attach attributes to game objects"
    end

    @attached_to = attach_to
    @attached_to.attach_attribute(self)
  end
end
