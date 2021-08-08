require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Yes
        class YesCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            make_emote event, player, room do

              no_target do
                to_player  "\"Yes,\" you say, nodding."
                to_other "#{player.name} says, \"Yes\" and nods."
              end

              self_target do
                to_player  "You nod in agreement with yourself."
                to_other "#{player.name} nods at #{player.pronoun(:reflexive)} strangely."
                to_deaf_other self[:to_other]
              end

              target do
                to_player  "You nod in agreement with #{event.target.name}."
                to_target "#{player.name} nods in your direction, agreeing."
                to_other "#{player.name} nods in agreement with #{event.target.name}."
                to_deaf_other self[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
