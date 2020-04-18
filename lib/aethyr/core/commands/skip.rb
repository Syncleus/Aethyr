require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module Skip
        class SkipHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["skip"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(SkipHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(skip)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              skip({:object => object, :post => post})
            when /^help (skip)$/i
              action_help_skip({})
            end
          end

          private
          def action_help_skip(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def skip(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You skip around cheerfully."
                to_other "#{player.name} skips around cheerfully."
                to_deaf_other "#{player.name} skips around cheerfully."
              end

              self_target do
                player.output 'How?'
              end

              target do
                to_player "You skip around #{event.target.name} cheerfully."
                to_target "#{player.name} skips around you cheerfully."
                to_other "#{player.name} skips around #{event.target.name} cheerfully."
                to_deaf_other "#{player.name} skips around #{event.target.name} cheerfully."
              end

            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SkipHandler)
      end
    end
  end
end
