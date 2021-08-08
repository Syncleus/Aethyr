require "aethyr/core/actions/action"

module Aethyr
  module Extend
    class CommandAction < Action
      def initialize(actor, **data)
        new_data = data.dup
        super(actor, **new_data)
        @player = actor
      end

      #Looks in player's inventory and room for name.
      #Then checks at global level for GOID.
      def find_object(name, event)
        if self[:actor].nil?
          return $manager.find(name, nil) || $manager.get_object(name)
        else
          return $manager.find(name, self[:actor]) || $manager.find(name, self[:actor].container) || $manager.get_object(name)
        end
      end
    end
  end
end
