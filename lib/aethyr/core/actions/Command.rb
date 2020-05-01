module Aethyr
  module Core
    module Actions
      class Command < Action
        def initialize(actor, **data)
          super(**data)
          @player = actor
        end
      end
    end
  end
end
