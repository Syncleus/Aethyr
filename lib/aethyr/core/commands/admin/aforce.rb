require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aforce
        class AforceHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["aforce"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aforce\s+(.*?)\s+(.*)$/i
              target = $1
              command = $2
              aforce({:target => target, :command => command})
            when /^help (aforce)$/i
              action_help_aforce({})
            end
          end

          private
          def action_help_aforce(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def aforce(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Force who?"
              return
            elsif object.is_a? Mobile
              unless object.info.redirect_output_to == player.goid
                object.info.redirect_output_to = player.goid

                after 10 do
                  object.info.redirect_output_to = nil
                end
              end
            end

            player.add_event(CommandParser.parse(object, event[:command]))
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AforceHandler)
      end
    end
  end
end
