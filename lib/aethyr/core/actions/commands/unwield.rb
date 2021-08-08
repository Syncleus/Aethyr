require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Unwield
        class UnwieldCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            if self[:weapon] == "right" || self[:weapon] == "left"
              weapon = player.equipment.get_wielded(self[:weapon])

              if weapon.nil?
                player.output "You are not wielding anything in your #{self[:weapon]} hand."
                return
              end
            elsif self[:weapon].nil?
              weapon = player.equipment.get_wielded
              if weapon.nil?
                player.output "You are not wielding anything."
                return
              end
            else
              weapon = player.equipment.find(self[:weapon])

              if weapon.nil?
                player.output "What are you trying to unwield?"
                return
              end

              if not [:left_wield, :right_wield, :dual_wield].include? player.equipment.position_of(weapon)
                player.output "You are not wielding #{weapon.name}."
                return
              end

            end

            if player.equipment.remove(weapon)
              player.inventory << weapon
              self[:to_player] = "You unwield #{weapon.name}."
              self[:to_other] = "#{player.name} unwields #{weapon.name}."
              room.out_event(event)
            else
              player.output "Could not unwield #{weapon.name}."
            end
          end

        end
      end
    end
  end
end
