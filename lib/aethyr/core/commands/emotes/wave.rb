require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Wave
        class WaveHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["wave"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(wave)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              wave({:object => object, :post => post})
            when /^help (wave)$/i
              action_help_wave({})
            end
          end

          private
          def action_help_wave(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def wave(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player  "You wave goodbye to everyone."
                to_other "#{player.name} waves goodbye to everyone."
              end

              self_target do
                player.output "Waving at someone?"
              end

              target do
                to_player  "You wave farewell to #{event.target.name}."
                to_target "#{player.name} waves farewell to you."
                to_other "#{player.name} waves farewell to #{event.target.name}."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(WaveHandler)
      end
    end
  end
end
