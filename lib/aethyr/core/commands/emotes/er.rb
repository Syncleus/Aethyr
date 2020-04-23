require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Er
        class ErHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["er"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(er)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              er({:object => object, :post => post})
            when /^help (er)$/i
              action_help_er({})
            end
          end

          private
          def action_help_er(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def er(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player "With a look of uncertainty, you say, \"Er...\""
                to_other "With a look of uncertainty, #{player.name} says, \"Er...\""
              end

              target do
                to_player "Looking at #{target.name} uncertainly, you say, \"Er...\""
                to_other "Looking at #{target.name} uncertainly, #{player.name} says, \"Er...\""
                to_target "Looking at you uncertainly, #{player.name} says, \"Er...\""
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(ErHandler)
      end
    end
  end
end
