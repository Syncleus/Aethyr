require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Yawn
        class YawnHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["yawn"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(yawn)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              yawn({:object => object, :post => post})
            when /^help (yawn)$/i
              action_help_yawn({})
            end
          end

          private
          def action_help_yawn(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def yawn(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You open your mouth in a wide yawn, then exhale loudly."
                to_other "#{player.name} opens #{player.pronoun(:possessive)} mouth in a wide yawn, then exhales loudly."
              end

              self_target do
                to_player "You yawn at how boring you are."
                to_other "#{player.name} yawns at #{player.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You yawn at #{event.target.name}, bored out of your mind."
                to_target "#{player.name} yawns at you, finding you boring."
                to_other "#{player.name} yawns at how boring #{event.target.name} is."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(YawnHandler)
      end
    end
  end
end
