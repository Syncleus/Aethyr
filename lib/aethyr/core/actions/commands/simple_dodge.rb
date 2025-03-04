require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module SimpleDodge
        class SimpleDodgeCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            return unless Combat.ready? player

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
              player.output "What are you trying to dodge?"
              return
            end

            if target.nil?
              target = selfs[0].player
            end

            player.last_target = target.goid

            b_self = selfs[0]
            if rand > 0.5
              b_self[:action] = :martial_miss
              b_self[:type] = :MartialCombat
              b_self[:to_other] = "#{player.name} twists away from #{target.name}'s attack."
              b_self[:to_player] = "#{player.name} twists away from your attack."
              b_self[:to_target] = "You manage to twist your body away from #{target.name}'s attack."
            end

            self[:target] = target
            self[:to_other] = "#{player.name} attempts to dodge #{target.name}'s attack."
            self[:to_target] = "#{player.name} attempts to dodge your attack."
            self[:to_player] = "You attempt to dodge #{target.name}'s attack."

            player.balance = false
            room.out_self self
          end

        end
      end
    end
  end
end
