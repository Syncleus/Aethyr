require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Wield
        class WieldHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["wield"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^wield\s+(.*?)(\s+(\w+))?$/i
              weapon = $1
              side = $3
              wield({:weapon => weapon, :side => side})
            when /^help (wield)$/i
              action_help_wield({})
            end
          end

          private
          def action_help_wield(event)
            @player.output <<'EOF'
Command: Wield item
Syntax: WIELD <item>
Syntax: WIELD <item> <left|right>

This command causes you to wield an item. The item must be wieldable and be present in your inventory.

You can also specify which hand with which to wield the weapon. If you do not, it will favor your right hand.

Example:

WIELD sword left


See also: UNWIELD

EOF
          end


          def wield(event)

            room = $manager.get_object(@player.container)
            player = @player
            weapon = player.inventory.find(event[:weapon])
            if weapon.nil?
              weapon = player.equipment.find(event[:weapon])
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

            if event[:side]
              side = event[:side]
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
              event[:to_player] = "You grip #{weapon.name} firmly in your #{side} hand."
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

              event[:to_player] = "You firmly grip #{weapon.name} and begin to wield it."
            end

            player.inventory.remove weapon
            event[:to_other] = "#{player.name} wields #{weapon.name}."
            room.out_event(event)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(WieldHandler)
      end
    end
  end
end
