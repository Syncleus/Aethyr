require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Bye
        class ByeHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["bye"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(bye)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              bye({:object => object, :post => post})
            when /^help (bye)$/i
              action_help_bye({})
            end
          end

          private
          def action_help_bye(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def bye(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You say a hearty \"Goodbye!\" to those around you."
                to_other "#{player.name} says a hearty \"Goodbye!\""
              end

              self_target do
                player.output "Goodbye."
              end

              target do
                to_player "You say \"Goodbye!\" to #{event.target.name}."
                to_target "#{player.name} says \"Goodbye!\" to you."
                to_other "#{player.name} says \"Goodbye!\" to #{event.target.name}"
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(ByeHandler)
      end
    end
  end
end
