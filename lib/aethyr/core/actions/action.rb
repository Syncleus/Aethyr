require 'aethyr/core/event'

module Aethyr
  module Extend
    class Action < Event
      def initialize(**data)
        super(**data)

        self.agent = data[:agent]
        self.target = data[:target]
      end

      def action
      end
    end
  end
end
