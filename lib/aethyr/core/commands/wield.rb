require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Wield
        class WieldHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "wield"
            see_also = ["UNWIELD"]
            syntax_formats = ["WIELD <item>", "WIELD <item> <left|right>"]
            aliases = nil
            content =  <<'EOF'
This command causes you to wield an item. The item must be wieldable and be present in your inventory.

You can also specify which hand with which to wield the weapon. If you do not, it will favor your right hand.

Example:

WIELD sword left

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["wield"], WieldHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^wield\s+(.*?)(\s+(\w+))?$/i
              weapon = $1
              side = $3
              wield({:weapon => weapon, :side => side})
            end
          end

          private
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
