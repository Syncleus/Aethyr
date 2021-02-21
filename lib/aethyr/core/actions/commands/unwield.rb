require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Unwield
        class UnwieldCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            if event[:weapon] == "right" || event[:weapon] == "left"
              weapon = player.equipment.get_wielded(event[:weapon])

              if weapon.nil?
                player.output "You are not wielding anything in your #{event[:weapon]} hand."
                return
              end
            elsif event[:weapon].nil?
              weapon = player.equipment.get_wielded
              if weapon.nil?
                player.output "You are not wielding anything."
                return
              end
            else
              weapon = player.equipment.find(event[:weapon])

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
              event[:to_player] = "You unwield #{weapon.name}."
              event[:to_other] = "#{player.name} unwields #{weapon.name}."
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
