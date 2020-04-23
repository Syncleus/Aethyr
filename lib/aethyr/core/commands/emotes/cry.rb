require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Cry
        class CryHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["cry"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(cry)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              cry({:object => object, :post => post})
            when /^help (cry)$/i
              action_help_cry({})
            end
          end

          private
          def action_help_cry(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def cry(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              default do
                to_player "Tears run down your face as you cry pitifully."
                to_other "Tears run down #{player.name}'s face as #{player.pronoun} cries pitifully."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(CryHandler)
      end
    end
  end
end
