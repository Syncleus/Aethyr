require "aethyr/core/objects/weapon"

module Aethyr
  module Extensions
    module Objects
      class Sword < Aethyr::Core::Objects::Weapon
        def initialize(*args)
          super
          @generic = "sword"
          info.weapon_type = :sword
          info.attack = 10
          info.defense = 5
        end
      end
    end
  end
end
