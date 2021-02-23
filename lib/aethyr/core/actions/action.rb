module Aethyr
  module Extend
    module Action
      def action; end
    end

    class Event
      include Aethyr::Extend::Action

      def initialize(**data)
        @data = data.freeze
      end
    end
  end
end
