require 'aethyr/core/objects/traits/sittable'
require 'aethyr/core/objects/game_object'

module Aethyr
  module Extensions
    module Objects
      class Chair < Aethyr::Core::Objects::GameObject
        include Sittable

        def initialize(*args)
          super
          @name = 'a nice chair'
          @generic = 'chair'
          @movable = false
        end
      end
    end
  end
end
