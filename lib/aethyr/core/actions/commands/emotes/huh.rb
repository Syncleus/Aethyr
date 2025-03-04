require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Huh
        class HuhCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            make_emote self, player, room do

              no_target do
                to_player  "\"Huh?\" you ask, confused."
                to_other "#{player.name} ask, \"Huh?\" and looks confused."
              end

              self_target do
                player.output "Well, huh!"
              end

              target do
                to_player "\"Huh?\" you ask #{self.target.name}."
                to_target "#{player.name} asks, \"Huh?\""
                to_other "#{player.name} asks #{self.target.name}, \"Huh?\""
              end
            end

          end

        end
      end
    end
  end
end
