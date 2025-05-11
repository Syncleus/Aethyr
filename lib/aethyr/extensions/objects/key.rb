require 'aethyr/core/objects/game_object'

module Aethyr
  module Extensions
    module Objects
      #Keys open doors.
      class Key < Aethyr::Core::Objects::GameObject
        def initialize(*args)
          super(*args)

          @generic = "key"
          @movable = true
          @short_desc = 'an unremarkable key'
        end
      end
    end
  end
end
