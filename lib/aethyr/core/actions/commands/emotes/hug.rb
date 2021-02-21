require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Hug
        class HugCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

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
      end
    end
  end
end
