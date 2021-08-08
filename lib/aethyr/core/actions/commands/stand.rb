require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Stand
        class StandCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            if not player.prone?
              player.output('You are already on your feet.')
              return
            elsif not player.balance
              player.output "You cannot stand while unbalanced."
              return
            end

            if player.sitting?
              object = $manager.find(player.sitting_on, room)
            else
              object = $manager.find(player.lying_on, room)
            end

            if player.stand
              self[:to_player] = 'You rise to your feet.'
              self[:to_other] = "#{player.name} stands up."
              self[:to_deaf_other] = self[:to_other]
              room.out_event(event)
              object.evacuated_by(player) unless object.nil?
            else
              player.output('You are unable to stand up.')
            end
          end

        end
      end
    end
  end
end
