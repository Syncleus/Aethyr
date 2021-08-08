require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Wave
        class WaveCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

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
      end
    end
  end
end
