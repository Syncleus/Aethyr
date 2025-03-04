require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Brb
        class BrbCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_player "\"I shall return shortly!\" you say to no one in particular."
                to_other "#{player.name} says, \"I shall return shortly!\" to no one in particular."
                to_blind_other "Someone says, \"I shall return shortly!\""
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "You let #{self.target.name} know you will return shortly."
                to_target "#{player.name} lets you know #{player.pronoun} will return shortly."
                to_other "#{player.name} tells #{self.target.name} that #{player.pronoun} will return shortly."
                to_blind_other "Someone says, \"I shall return shortly!\""
              end
            end

          end

        end
      end
    end
  end
end
