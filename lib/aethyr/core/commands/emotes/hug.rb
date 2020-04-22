require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Hug
        class HugHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["hug"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(HugHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(hug)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              hug({:object => object, :post => post})
            when /^help (hug)$/i
              action_help_hug({})
            end
          end

          private
          def action_help_hug(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def hug(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                player.output "Who are you trying to hug?"
              end

              self_target do
                to_player 'You wrap your arms around yourself and give a tight squeeze.'
                to_other "#{player.name} gives #{player.pronoun(:reflexive)} a tight squeeze."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You give #{event.target.name} a great big hug."
                to_target "#{player.name} gives you a great big hug."
                to_other "#{player.name} gives #{event.target.name} a great big hug."
                to_blind_target "Someone gives you a great big hug."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(HugHandler)
      end
    end
  end
end
