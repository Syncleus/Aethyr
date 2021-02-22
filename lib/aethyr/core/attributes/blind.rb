require 'aethyr/core/objects/attributes/attribute'
require 'aethyr/core/objects/living'

class Blind < Attribute
  def initialize(attach_to)
    if not attach_to.is_a? LivingObject
      raise ArgumentError.new "Can only attach the Blind attribute to LivingObjects"
    end

    super(attach_to)

    @attached_to.subscribe(self)
  end

  def pre_look(data)
    data[:can_look] = false
    data[:reason] = "You cannot see while you are blind"
  end
end
