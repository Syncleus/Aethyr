require 'aethyr/core/objects/game_object'

module Aethyr
  module Core
    module Objects
      #A prop is basically just a GameObject but is nice to use for creating objects
      #in the game that don't need any special properties (use the ACPROP command).
      class Prop < GameObject
        def initialize(*args)
          super(*args)
          @generic = "prop"
        end
      end
    end
  end
end
