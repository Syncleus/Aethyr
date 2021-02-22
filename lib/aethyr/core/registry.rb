module Aethyr
    module Extend
        class HandlerRegistry
          @@handlers = Set.new

            def self.register_handler(new_handler)
              raise "Bad handler!" unless new_handler
              unless @@handlers.include? new_handler
                  @@handlers << new_handler
              end
            end

            def self.get_handlers
                return @@handlers.dup
            end

            def self.handle(manager)
              @@handlers.each do |handler|
                manager.subscribe(handler, on: :object_added)
              end
              nil
            end
        end
    end
end

require 'aethyr/core/util/all-commands'
