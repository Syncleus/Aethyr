require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Snicker
        class SnickerHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["snicker"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(snicker)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              snicker({:object => object, :post => post})
            when /^help (snicker)$/i
              action_help_snicker({})
            end
          end

          private
          def action_help_snicker(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def snicker(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player  "You snicker softly to yourself."
                to_other "You hear #{player.name} snicker softly."
                to_blind_other "You hear someone snicker softly."
              end

              self_target do
                player.output "What are you snickering about?"
              end

              target do
                to_player  "You snicker at #{event.target.name} under your breath."
                to_target "#{player.name} snickers at you under #{player.pronoun(:possessive)} breath."
                to_other "#{player.name} snickers at #{event.target.name} under #{player.pronoun(:possessive)} breath."
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SnickerHandler)
      end
    end
  end
end
