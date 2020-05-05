require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module No
        class NoCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player  "\"No,\" you say, shaking your head."
                to_other "#{player.name} says, \"No\" and shakes #{player.pronoun(:possessive)} head."
              end
              self_target do
                to_player  "You shake your head negatively in your direction. You are kind of strange."
                to_other "#{player.name} shakes #{player.pronoun(:possessive)} head at #{player.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end
              target do
                to_player  "You shake your head, disagreeing with #{event.target.name}."
                to_target "#{player.name} shakes #{player.pronoun(:possessive)} head in your direction, disagreeing."
                to_other "#{player.name} shakes #{player.pronoun(:possessive)} head in disagreement with #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
