require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Nod
        class NodCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You nod your head."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player 'You nod to yourself thoughtfully.'
                to_other "#{player.name} nods to #{player.pronoun(:reflexive)} thoughtfully."
                to_deaf_other event[:to_other]
              end

              target do

                to_player "You nod your head towards #{event.target.name}."
                to_target "#{player.name} nods #{player.pronoun(:possessive)} head towards you."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head towards #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
      end
    end
  end
end
