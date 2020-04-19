require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Slash
        class SlashHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["slash"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(SlashHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^slash$/i
              slash({})
            when /^slash\s+(.*)$/i
              target = $1
              slash({:target => target})
            when /^help (slash)$/i
              action_help_slash({})
            end
          end

          private
          def action_help_slash(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def slash(event)

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
        Aethyr::Extend::HandlerRegistry.register_handler(SlashHandler)
      end
    end
  end
end