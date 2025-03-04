require 'aethyr/core/event'

module Aethyr
  module Extend
    class Action < Event
      def initialize(agent: nil, target: nil, **data)
        super(:action, **data)

        self.agent = agent
        self.target = target
      end

      def action
      end
    end
  end
end
