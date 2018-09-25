module Aethyr
    module Extend
        class CommandRegistry
            @@handlers = Hash.new
            
            def self.register_handler(new_handler)
              raise "Bad handler!" unless new_handler
              unless @@handlers.include? new_handler
                  @@handlers[new_handler] = new_handler.new
              end
            end
            
            def self.get_handlers
                return @@handlers.values.dup
            end
            
            def self.handle(input, player)
              @@handlers.values.each do |handler|
                e = handler.handle(input, player)
                return e unless e.nil?
              end
              nil
            end
        end
    end
end