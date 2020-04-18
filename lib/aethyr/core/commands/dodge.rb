require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Dodge
        class DodgeHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["dodge"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(DodgeHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^dodge(\s+(.*))?$/i
              target = $2 if $2
              simple_dodge({:target => target})
            when /^help (dodge)$/i
              action_help_dodge({})
            end
          end

          private
          def action_help_dodge(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def simple_dodge(event)

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
        Aethyr::Extend::HandlerRegistry.register_handler(DodgeHandler)
      end
    end
  end
end
