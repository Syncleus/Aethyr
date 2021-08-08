require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Slash
        class SlashCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            return if not Combat.ready? player

            weapon = get_weapon(player, :slash)
            if weapon.nil?
              player.output "You are not wielding a weapon you can slash with."
              return
            end

            target = (event.target && room.find(event.target)) || room.find(player.last_target)

            if target.nil?
              player.output "Who are you trying to attack?"
              return
            else
              return unless Combat.valid_target? player, target
            end

            player.last_target = target.goid

            event.target = target

            self[:to_other] = "#{weapon.name} flashes as #{player.name} swings it at #{target.name}."
            self[:to_target] = "#{weapon.name} flashes as #{player.name} swings it towards you."
            self[:to_player] = "#{weapon.name} flashes as you swing it towards #{target.name}."
            self[:attack_weapon] = weapon
            self[:blockable] = true

            player.balance = false
            player.info.in_combat = true
            target.info.in_combat = true

            room.out_event event

            self[:action] = :weapon_hit
            self[:combat_action] = :slash
            self[:to_other] = "#{player.name} slashes across #{target.name}'s torso with #{weapon.name}."
            self[:to_target] = "#{player.name} slashes across your torso with #{weapon.name}."
            self[:to_player] = "You slash across #{target.name}'s torso with #{weapon.name}."

            Combat.future_event event

          end

        end
      end
    end
  end
end
