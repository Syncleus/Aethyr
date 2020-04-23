require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Hi
        class HiHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["hi"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(hi)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              hi({:object => object, :post => post})
            when /^help (hi)$/i
              action_help_hi({})
            end
          end

          private
          def action_help_hi(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def hi(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "\"Hi!\" you greet those around you."
                to_other "#{player.name} greets those around with a \"Hi!\""
              end

              self_target do
                player.output "Hi."
              end

              target do
                to_player "You say \"Hi!\" in greeting to #{event.target.name}."
                to_target "#{player.name} greets you with a \"Hi!\""
                to_other "#{player.name} greets #{event.target.name} with a hearty \"Hi!\""
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(HiHandler)
      end
    end
  end
end
