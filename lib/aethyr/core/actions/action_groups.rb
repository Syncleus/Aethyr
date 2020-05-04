module Aethyr
  module Core
    module Actions
      class ActionGroup
        attr_reader :concurrency

        def initialize(concurrency, *actions)
          @actions = *actions
          @concurrency = concurrency

          raise "Invalid concurrency type" if @concurrency != :parallel && @concurrency != :sequenial
          raise "actions needs to have at least two values" if @actions.nil? || @actions.length < 2
        end

        def each
          @actions.each { |e| yield e }
        end
      end

    end
  end
end
