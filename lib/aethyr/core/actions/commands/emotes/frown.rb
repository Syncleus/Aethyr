require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Frown
        class FrownCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do
              no_target do
                to_player "The edges of your mouth turn down as you frown."
                to_other "The edges of #{player.name}'s mouth turn down as #{player.pronoun} frowns."
                to_deaf_other self[:to_other]
              end

              self_target do
                to_player "You frown sadly at yourself."
                to_other "#{player.name} frowns sadly at #{self.target.pronoun(:reflexive)}."
                to_deaf_other self[:to_other]
              end

              target do
                to_player "You frown at #{self.target.name} unhappily."
                to_target "#{player.name} frowns at you unhappily."
                to_deaf_target self[:to_target]
                to_other "#{player.name} frowns at #{self.target.name} unhappily."
                to_deaf_other self[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
