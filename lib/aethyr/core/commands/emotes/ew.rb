require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Ew
        class EwHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["ew"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(ew)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              ew({:object => object, :post => post})
            when /^help (ew)$/i
              action_help_ew({})
            end
          end

          private
          def action_help_ew(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def ew(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "\"Ewww!\" you exclaim, looking disgusted."
                to_other "#{player.name} exclaims, \"Eww!!\" and looks disgusted."
                to_deaf_other "#{player.name} looks disgusted."
                to_blind_other "Somone exclaims, \"Eww!!\""
              end

              self_target do
                player.output "You think you are digusting?"
              end

              target do
                to_player "You glance at #{event.target.name} and say \"Ewww!\""
                to_target "#{player.name} glances in your direction and says, \"Ewww!\""
                to_deaf_other "#{player.name} gives #{event.target.name} a disgusted look."
                to_blind_other "Somone exclaims, \"Eww!!\""
                to_other "#{player.name} glances at #{event.target.name}, saying \"Ewww!\""
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(EwHandler)
      end
    end
  end
end
