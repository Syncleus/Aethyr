require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module SimpleBlock
        class SimpleBlockCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            return if not Combat.ready? player

            weapon = get_weapon(player, :block)
            if weapon.nil?
              player.output "You are not wielding a weapon you can block with."
              return
            end

            target = (self.target && room.find(self.target)) || room.find(player.last_target)

            if target == player
              player.output "You cannot block yourself."
              return
            elsif target
              selfs = Combat.find_selfs(:player => target, :target => player, :blockable => true)
            else
              selfs = Combat.find_selfs(:target => player, :blockable => true)
            end

            if selfs.empty?
              player.output "What are you trying to block?"
              return
            end

            if target.nil?
              target = selfs[0].player
            end

            player.last_target = target.goid

            b_self = selfs[0]
            if rand > 0.5
              b_self[:action] = :weapon_block
              b_self[:type] = :WeaponCombat
              b_self[:to_other] = "#{player.name} deftly blocks #{target.name}'s attack with #{weapon.name}."
              b_self[:to_player] = "#{player.name} deftly blocks your attack with #{weapon.name}."
              b_self[:to_target] = "You deftly block #{target.name}'s attack with #{weapon.name}."
            end

            self[:target] = target
            self[:to_other] = "#{player.name} raises #{player.pronoun(:possessive)} #{weapon.generic} to block #{target.name}'s attack."
            self[:to_target] = "#{player.name} raises #{player.pronoun(:possessive)} #{weapon.generic} to block your attack."
            self[:to_player] = "You raise your #{weapon.generic} to block #{target.name}'s attack."

            player.balance = false
            room.out_self self
          end

        end
      end
    end
  end
end
