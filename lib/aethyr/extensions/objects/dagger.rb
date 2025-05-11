require "aethyr/core/objects/weapon"

module Aethyr
  module Extensions
    module Objects
      class Dagger < Aethyr::Core::Objects::Weapon
        def initialize(*args)
          super
          @generic = "dagger"
          info.weapon_type = :dagger
          info.attack = 5
          info.defense = 5
        end
      end
    end
  end
end
