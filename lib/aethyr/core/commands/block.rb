require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Block
        class BlockHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["block"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^block(\s+(.*))?$/i
              target = $2
              simple_block({:target => target})
            when /^help (block)$/i
              action_help_block({})
            end
          end

          private
          def action_help_block(event)
            @player.output <<'EOF'
Command: Simple Block
Syntax: BLOCK <target>
Syntax: BLOCK

This is a simple block which uses your weapon to attempt to block an opponent's attack. If you are not wielding a weapon, you will attempt a block with your bare hands.


See also: THRUST, STATUS

EOF
          end


          def simple_block(event)

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
        Aethyr::Extend::HandlerRegistry.register_handler(BlockHandler)
      end
    end
  end
end
