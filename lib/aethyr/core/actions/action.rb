require 'aethyr/core/event'

module Aethyr
  module Extend
    class Action < Event
      def initialize(agent, **data)
        data[:agent] = agent
        super(:action, **data)
      end

      def action
      end
    end
  end
end
