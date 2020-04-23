require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Smile
        class SmileHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["smile"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(smile)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              smile({:object => object, :post => post})
            when /^help (smile)$/i
              action_help_smile({})
            end
          end

          private
          def action_help_smile(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def smile(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              self_target do
                to_player "You smile happily at yourself."
                to_other "#{player.name} smiles at #{player.pronoun(:reflexive)} sillily."
              end

              target do
                to_player "You smile at #{event.target.name} kindly."
                to_target "#{player.name} smiles at you kindly."
                to_other "#{player.name} smiles at #{event.target.name} kindly."
              end

              no_target do
                to_player "You smile happily."
                to_other "#{player.name} smiles happily."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SmileHandler)
      end
    end
  end
end
