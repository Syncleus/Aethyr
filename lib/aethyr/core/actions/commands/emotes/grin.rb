require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Grin
        class GrinCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_player 'You grin widely, flashing all your teeth.'
                to_other "#{player.name} grins widely, flashing all #{player.pronoun(:possessive)} teeth."
                to_deaf_other self[:to_other]
              end

              self_target do
                to_player "You grin madly at yourself."
                to_other "#{player.name} grins madly at #{self.target.pronoun(:reflexive)}."
                to_deaf_other self[:to_other]
              end

              target do
                to_player "You give #{self.target.name} a wide grin."
                to_target "#{player.name} gives you a wide grin."
                to_deaf_target self[:to_target]
                to_other "#{player.name} gives #{self.target.name} a wide grin."
                to_deaf_other self[:to_other]
              end

            end
          end

        end
      end
    end
  end
end
