require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module SimpleBlock
        class SimpleBlockCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            return if not Combat.ready? player

            weapon = get_weapon(player, :block)
            if weapon.nil?
              player.output "You are not wielding a weapon you can block with."
              return
            end

            target = (event.target && room.find(event.target)) || room.find(player.last_target)

            if target == player
              player.output "You cannot block yourself."
              return
            elsif target
              events = Combat.find_events(:player => target, :target => player, :blockable => true)
            else
              events = Combat.find_events(:target => player, :blockable => true)
            end

            if events.empty?
              player.output "What are you trying to block?"
              return
            end

            if target.nil?
              target = events[0].player
            end

            player.last_target = target.goid

            b_event = events[0]
            if rand > 0.5
              b_event[:action] = :weapon_block
              b_event[:type] = :WeaponCombat
              b_event[:to_other] = "#{player.name} deftly blocks #{target.name}'s attack with #{weapon.name}."
              b_event[:to_player] = "#{player.name} deftly blocks your attack with #{weapon.name}."
              b_event[:to_target] = "You deftly block #{target.name}'s attack with #{weapon.name}."
            end

            event[:target] = target
            event[:to_other] = "#{player.name} raises #{player.pronoun(:possessive)} #{weapon.generic} to block #{target.name}'s attack."
            event[:to_target] = "#{player.name} raises #{player.pronoun(:possessive)} #{weapon.generic} to block your attack."
            event[:to_player] = "You raise your #{weapon.generic} to block #{target.name}'s attack."

            player.balance = false
            room.out_event event
          end

        end
      end
    end
  end
end
