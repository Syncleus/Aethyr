require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Cheer
        class CheerCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You throw your hands in the air and cheer wildly!"
                to_other "#{player.name} throws #{player.pronoun(:possessive)} hands in the air as #{player.pronoun} cheers wildy!"
                to_blind_other "You hear someone cheering."
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "Beaming at #{event.target.name}, you throw your hands up and cheer for #{event.target.pronoun(:objective)}."
                to_target "Beaming at you, #{player.name} throws #{player.pronoun(:possessive)} hands up and cheers for you."
                to_other "#{player.name} throws #{player.pronoun(:possessive)} hands up and cheers for #{event.target.name}."
                to_blind_other "You hear someone cheering."
              end
            end
          end

        end
      end
    end
  end
end
