require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module Bow
        class BowHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["bow"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(BowHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(bow)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              bow({:object => object, :post => post})
            when /^help (bow)$/i
              action_help_bow({})
            end
          end

          private
          def action_help_bow(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def bow(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You bow deeply and respectfully."
                to_other "#{player.name} bows deeply and respectfully."
                to_deaf_other event[:to_other]
              end

              self_target do
                player.output  "Huh?"
              end

              target do
                to_player  "You bow respectfully towards #{event.target.name}."
                to_target "#{player.name} bows respectfully before you."
                to_other "#{player.name} bows respectfully towards #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(BowHandler)
      end
    end
  end
end
