require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Shrug
        class ShrugCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_player "You shrug your shoulders."
                to_other "#{player.name} shrugs #{player.pronoun(:possessive)} shoulders."
                to_deaf_other self[:to_other]
              end

              self_target do
                player.output "Don't just shrug yourself off like that!"

              end

              target do
                to_player  "You give #{self.target.name} a brief shrug."
                to_target "#{player.name} gives you a brief shrug."
                to_other "#{player.name} gives #{self.target.name} a brief shrug."
                to_deaf_other self[:to_other]
                to_deaf_target self[:to_target]
              end
            end

          end

        end
      end
    end
  end
end
