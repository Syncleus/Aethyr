require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Kick
        class KickCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            return if not Combat.ready? player

            target = (event.target && room.find(event.target)) || room.find(player.last_target)

            if target.nil?
              player.output "Who are you trying to attack?"
              return
            else
              return unless Combat.valid_target? player, target
            end

            player.last_target = target.goid

            event.target = target

            event[:to_other] = "#{player.name} kicks #{player.pronoun(:possessive)} foot out at #{target.name}."
            event[:to_target] = "#{player.name} kicks #{player.pronoun(:possessive)} foot at you."
            event[:to_player] = "You balance carefully and kick your foot out towards #{target.name}."
            event[:blockable] = true

            player.balance = false
            player.info.in_combat = true
            target.info.in_combat = true

            room.out_event event

            event[:action] = :martial_hit
            event[:combat_action] = :kick
            event[:to_other] = "#{player.name} kicks #{target.name} with considerable violence."
            event[:to_target] = "#{player.name} kicks you rather violently."
            event[:to_player] = "Your kick makes good contact with #{target.name}."

            Combat.future_event event
          end

        end
      end
    end
  end
end
