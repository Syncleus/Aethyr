require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Smile
        class SmileCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              self_target do
                to_player "You smile happily at yourself."
                to_other "#{player.name} smiles at #{player.pronoun(:reflexive)} sillily."
              end

              target do
                to_player "You smile at #{self.target.name} kindly."
                to_target "#{player.name} smiles at you kindly."
                to_other "#{player.name} smiles at #{self.target.name} kindly."
              end

              no_target do
                to_player "You smile happily."
                to_other "#{player.name} smiles happily."
              end
            end
          end

        end
      end
    end
  end
end
