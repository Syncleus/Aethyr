require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Blush
        class BlushHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["blush"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(blush)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              blush({:object => object, :post => post})
            when /^help (blush)$/i
              action_help_blush({})
            end
          end

          private
          def action_help_blush(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def blush(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You feel the blood rush to your cheeks and you look down, blushing."
                to_other "#{player.name}'s face turns bright red as #{player.pronoun} looks down, blushing."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player "You blush at your foolishness."
                to_other "#{player.name} blushes at #{event.target.pronoun(:possessive)} foolishness."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "Your face turns red and you blush at #{event.target.name} uncomfortably."
                to_target "#{player.name} blushes in your direction."
                to_deaf_target event[:to_target]
                to_other "#{player.name} blushes at #{event.target.name}, clearly uncomfortable."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(BlushHandler)
      end
    end
  end
end
