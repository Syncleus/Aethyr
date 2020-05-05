require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Ponder
        class PonderCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You ponder that idea for a moment."
                to_other "#{player.name} looks thoughtful as #{player.pronoun} ponders a thought."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player  "You look down in deep thought at your navel."
                to_other "#{player.name} looks down thoughtfully at #{player.pronoun(:possessive)} navel."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You give #{event.target.name} a thoughtful look as you reflect and ponder."
                to_target "#{player.name} gives you a thoughtful look and seems to be reflecting upon something."
                to_other "#{player.name} gives #{event.target.name} a thoughtful look and appears to be absorbed in reflection."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
      end
    end
  end
end
