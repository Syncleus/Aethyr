require "aethyr/core/actions/action"

module Aethyr
  module Extend
    class CommandAction < Action
      def initialize(actor, **data)

        super(**data)
        @player = actor
      end

      #Looks in player's inventory and room for name.
      #Then checks at global level for GOID.
      def find_object(name, event)
        if event[:actor].nil?
          return $manager.find(name, nil) || $manager.get_object(name)
        else
          return $manager.find(name, event[:actor]) || $manager.find(name, event[:actor].container) || $manager.get_object(name)
        end
      end
    end
  end
end
