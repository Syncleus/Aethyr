module Aethyr
  module Core
    module Actions
      module Action
        def concurrency
          return :single
        end

        def action()
        end
      end

      class Event
        include Aethyr::Core::Actions::Action

        def initialize(**data)
          @data = data.freeze
        end
      end
    end
  end
end
