require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Brb
        class BrbHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["brb"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(brb)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              brb({:object => object, :post => post})
            when /^help (brb)$/i
              action_help_brb({})
            end
          end

          private
          def action_help_brb(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def brb(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "\"I shall return shortly!\" you say to no one in particular."
                to_other "#{player.name} says, \"I shall return shortly!\" to no one in particular."
                to_blind_other "Someone says, \"I shall return shortly!\""
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "You let #{event.target.name} know you will return shortly."
                to_target "#{player.name} lets you know #{player.pronoun} will return shortly."
                to_other "#{player.name} tells #{event.target.name} that #{player.pronoun} will return shortly."
                to_blind_other "Someone says, \"I shall return shortly!\""
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(BrbHandler)
      end
    end
  end
end
