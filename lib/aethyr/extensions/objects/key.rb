require 'aethyr/core/objects/game_object'

#Keys open doors.
class Key < GameObject
  def initialize(*args)
    super(*args)

    @generic = "key"
    @movable = true
    @short_desc = 'an unremarkable key'
  end
end
