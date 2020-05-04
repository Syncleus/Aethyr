require "aethyr/core/actions/action"

module Aethyr
  module Core
    module Actions
      class CommandAction < Event
        def initialize(actor, **data)
          super(**data)
          @player = actor
        end
      end
    end
  end
end
