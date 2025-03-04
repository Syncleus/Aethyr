require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Wield
        class WieldCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            weapon = player.inventory.find(self[:weapon])
            if weapon.nil?
              weapon = player.equipment.find(self[:weapon])
              if weapon and player.equipment.get_all_wielded.include? weapon
                player.output "You are already wielding that."
              else
                player.output "What are you trying to wield?"
              end
              return
            end

            if not weapon.is_a? Weapon
              player.output "#{weapon.name} is not wieldable."
              return
            end

            if self[:side]
              side = self[:side]
              if side != "right" and side != "left"
                player.output "Which hand?"
                return
              end

              result = player.equipment.check_wield(weapon, "#{side} wield")
              if result
                player.output result
                return
              end

              result = player.equipment.wear(weapon, "#{side} wield")
              if result.nil?
                player.output "You are unable to wield that."
                return
              end
              self[:to_player] = "You grip #{weapon.name} firmly in your #{side} hand."
            else
              result = player.equipment.check_wield(weapon)

              if result
                player.output result
                return
              end

              result = player.equipment.wear(weapon)
              if result.nil?
                player.output "You are unable to wield that weapon."
                return
              end

              self[:to_player] = "You firmly grip #{weapon.name} and begin to wield it."
            end

            player.inventory.remove weapon
            self[:to_other] = "#{player.name} wields #{weapon.name}."
            room.out_self(self)
          end

        end
      end
    end
  end
end
