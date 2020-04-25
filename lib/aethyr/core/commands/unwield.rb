require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Unwield
        class UnwieldHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "unwield"
            see_also = ["WIELD"]
            syntax_formats = ["UNWIELD", "UNWIELD <weapon>", "UNWIELD <left|right>"]
            aliases = nil
            content =  <<'EOF'
This command will cause you to unwield a weapon and place it in your inventory. If you do not specify which weapon or which hand you are using to hold the weapon, it will favor your right hand.

Example:

UNWIELD halberd
UNWIELD left

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["unwield"], UnwieldHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^unwield(\s+(.*))?$/i
              weapon = $2
              unwield({:weapon => weapon})
            end
          end

          private
          def unwield(event)

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
        Aethyr::Extend::HandlerRegistry.register_handler(UnwieldHandler)
      end
    end
  end
end
