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
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

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

            event[:to_other] = "#{weapon.name} flashes as #{player.name} swings it at #{target.name}."
            event[:to_target] = "#{weapon.name} flashes as #{player.name} swings it towards you."
            event[:to_player] = "#{weapon.name} flashes as you swing it towards #{target.name}."
            event[:attack_weapon] = weapon
            event[:blockable] = true

            player.balance = false
            player.info.in_combat = true
            target.info.in_combat = true

            room.out_event event

            event[:action] = :weapon_hit
            event[:combat_action] = :slash
            event[:to_other] = "#{player.name} slashes across #{target.name}'s torso with #{weapon.name}."
            event[:to_target] = "#{player.name} slashes across your torso with #{weapon.name}."
            event[:to_player] = "You slash across #{target.name}'s torso with #{weapon.name}."

            Combat.future_event event

          end

        end
      end
    end
  end
end
