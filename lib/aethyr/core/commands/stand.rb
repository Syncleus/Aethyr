require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Stand
        class StandHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["stand"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(StandHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^stand$/i
              stand({})
            when /^help (stand)$/i
              action_help_stand({})
            end
          end

          private
          def action_help_stand(event)
            @player.output <<'EOF'
Command: Stand
Syntax: STAND

Stand up if you are sitting down.


See also: SIT

EOF
          end


          def stand(event)

            room = $manager.get_object(@player.container)
            player = @player
            if not player.prone?
              player.output('You are already on your feet.')
              return
            elsif not player.balance
              player.output "You cannot stand while unbalanced."
              return
            end

            if player.sitting?
              object = $manager.find(player.sitting_on, room)
            else
              object = $manager.find(player.lying_on, room)
            end

            if player.stand
              event[:to_player] = 'You rise to your feet.'
              event[:to_other] = "#{player.name} stands up."
              event[:to_deaf_other] = event[:to_other]
              room.out_event(event)
              object.evacuated_by(player) unless object.nil?
            else
              player.output('You are unable to stand up.')
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(StandHandler)
      end
    end
  end
end