require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Shrug
        class ShrugCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You shrug your shoulders."
                to_other "#{player.name} shrugs #{player.pronoun(:possessive)} shoulders."
                to_deaf_other event[:to_other]
              end

              self_target do
                player.output "Don't just shrug yourself off like that!"

              end

              target do
                to_player  "You give #{event.target.name} a brief shrug."
                to_target "#{player.name} gives you a brief shrug."
                to_other "#{player.name} gives #{event.target.name} a brief shrug."
                to_deaf_other event[:to_other]
                to_deaf_target event[:to_target]
              end
            end

          end

        end
      end
    end
  end
end
