require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Kick
        class KickCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            return if not Combat.ready? player

            target = (self.target && room.find(self.target)) || room.find(player.last_target)

            if target.nil?
              player.output "Who are you trying to attack?"
              return
            else
              return unless Combat.valid_target? player, target
            end

            player.last_target = target.goid

            self.target = target

            self[:to_other] = "#{player.name} kicks #{player.pronoun(:possessive)} foot out at #{target.name}."
            self[:to_target] = "#{player.name} kicks #{player.pronoun(:possessive)} foot at you."
            self[:to_player] = "You balance carefully and kick your foot out towards #{target.name}."
            self[:blockable] = true

            player.balance = false
            player.info.in_combat = true
            target.info.in_combat = true

            room.out_self self

            self[:action] = :martial_hit
            self[:combat_action] = :kick
            self[:to_other] = "#{player.name} kicks #{target.name} with considerable violence."
            self[:to_target] = "#{player.name} kicks you rather violently."
            self[:to_player] = "Your kick makes good contact with #{target.name}."

            Combat.future_self self
          end

        end
      end
    end
  end
end
