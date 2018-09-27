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
                manager.subscribe(handler)
              end
              nil
            end
            
#            def self.help_handle(input, player)
#              @@handlers.values.each do |handler|
#                next unless handler.is_a? Aethyr::Extend::HandleHelp
#                e = handler.help_handle(input, player)
#                return e unless e.nil?
#              end
#              nil
#            end
#            
#            def self.help_topics(player)
#              topics = []
#              @@handlers.values.each do |handler|
#                next unless handler.is_a? Aethyr::Extend::HandleHelp
#                topics.push *(handler.commands)
#              end
#              topics
#            end
        end
    end
end

require 'aethyr/core/util/all-commands'