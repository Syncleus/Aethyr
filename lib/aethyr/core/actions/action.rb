module Aethyr
  module Core
    module Actions
      class Action
        def initialize(**data)
          @data = data.freeze
        end

        def action()
        end
      end
    end
  end
end
