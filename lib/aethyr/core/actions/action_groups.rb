module Aethyr
  module Extend
    class ActionGroup
      attr_reader :concurrency

      def initialize(concurrency, *actions)
        @actions = *actions
        @concurrency = concurrency

        if @concurrency != :parallel && @concurrency != :sequenial
          raise 'Invalid concurrency type'
          end
        if @actions.nil? || @actions.length < 2
          raise 'actions needs to have at least two values'
          end
      end

      def each
        @actions.each { |e| yield e }
      end
    end
  end
end
