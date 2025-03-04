require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Skip
        class SkipCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_player "You skip around cheerfully."
                to_other "#{player.name} skips around cheerfully."
                to_deaf_other "#{player.name} skips around cheerfully."
              end

              self_target do
                player.output 'How?'
              end

              target do
                to_player "You skip around #{self.target.name} cheerfully."
                to_target "#{player.name} skips around you cheerfully."
                to_other "#{player.name} skips around #{self.target.name} cheerfully."
                to_deaf_other "#{player.name} skips around #{self.target.name} cheerfully."
              end

            end
          end

        end
      end
    end
  end
end
