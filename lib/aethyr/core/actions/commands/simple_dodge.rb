require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module SimpleDodge
        class SimpleDodgeCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            return unless Combat.ready? player

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
              player.output "What are you trying to dodge?"
              return
            end

            if target.nil?
              target = events[0].player
            end

            player.last_target = target.goid

            b_event = events[0]
            if rand > 0.5
              b_event[:action] = :martial_miss
              b_event[:type] = :MartialCombat
              b_event[:to_other] = "#{player.name} twists away from #{target.name}'s attack."
              b_event[:to_player] = "#{player.name} twists away from your attack."
              b_event[:to_target] = "You manage to twist your body away from #{target.name}'s attack."
            end

            event[:target] = target
            event[:to_other] = "#{player.name} attempts to dodge #{target.name}'s attack."
            event[:to_target] = "#{player.name} attempts to dodge your attack."
            event[:to_player] = "You attempt to dodge #{target.name}'s attack."

            player.balance = false
            room.out_event event
          end

        end
      end
    end
  end
end
