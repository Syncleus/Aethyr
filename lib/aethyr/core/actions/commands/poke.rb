require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Poke
        class PokeCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                player.output "Who are you trying to poke?"
              end

              self_target do
                to_player  "You poke yourself in the eye. 'Ow!'"
                to_other "#{player.name} pokes #{player.pronoun(:reflexive)} in the eye."
                to_deaf_other event[:to_other]
              end

              target do
                to_player  "You poke #{event.target.name} playfully."
                to_target "#{player.name} pokes you playfully."
                to_blind_target "Someone pokes you playfully."
                to_deaf_target event[:to_target]
                to_other "#{player.name} pokes #{event.target.name} playfully."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
      end
    end
  end
end
