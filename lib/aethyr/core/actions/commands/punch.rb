require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Punch
        class PunchCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            return unless Combat.ready? player

            target = (event.target && room.find(event.target)) || room.find(player.last_target)

            if target.nil?
              player.output "Who are you trying to attack?"
              return
            else
              return unless Combat.valid_target? player, target
            end

            player.last_target = target.goid

            event.target = target

            event[:to_other] = "#{player.name} swings #{player.pronoun(:possessive)} clenched fist at #{target.name}."
            event[:to_target] = "#{player.name} swings #{player.pronoun(:possessive)} fist straight towards your face."
            event[:to_player] = "You clench your hand into a fist and swing it at #{target.name}."
            event[:blockable] = true

            player.balance = false
            player.info.in_combat = true
            target.info.in_combat = true

            room.out_event event

            event[:action] = :martial_hit
            event[:combat_action] = :punch
            event[:to_other] = "#{player.name} punches #{target.name} directly in the face."
            event[:to_target] = "You stagger slightly as #{player.name} punches you in the face."
            event[:to_player] = "Your fist lands squarely in #{target.name}'s face."

            Combat.future_event event
          end

        end
      end
    end
  end
end
