module Aethyr
    module Extend
        class HandlerRegistry
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
            
            def self.input_handle(input, player)
              @@handlers.values.each do |handler|
                next unless handler.is_a? Aethyr::Extend::InputHandler
                e = handler.input_handle(input, player)
                return e unless e.nil?
              end
              nil
            end
            
            def self.help_handle(input, player)
              @@handlers.values.each do |handler|
                next unless handler.is_a? Aethyr::Extend::HandleHelp
                e = handler.help_handle(input, player)
                return e unless e.nil?
              end
              nil
            end
            
            def self.help_topics(player)
              topics = []
              @@handlers.values.each do |handler|
                next unless handler.is_a? Aethyr::Extend::HandleHelp
                topics.push *(handler.commands)
              end
              topics
            end
        end
    end
end