require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Gait
        class GaitHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["gait"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(GaitHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^gait(\s+(.*))?$/i
              phrase = $2 if $2
              gait({:phrase => phrase})
            when /^help (gait)$/i
              action_help_gait({})
            end
          end

          private
          def action_help_gait(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def gait(event)

            room = $manager.get_object(@player.container)
            player = @player
            if event[:phrase].nil?
              if player.info.entrance_message
                player.output "When you move, it looks something like:", true
                player.output player.exit_message("north")
              else
                player.output "You are walking normally."
              end
            elsif event[:phrase].downcase == "none"
              player.info.entrance_message = nil
              player.info.exit_message = nil
              player.output "You will now walk normally."
            else
              player.info.entrance_message = "#{event[:phrase]}, !name comes in from !direction."
              player.info.exit_message = "#{event[:phrase]}, !name leaves to !direction."

              player.output "When you move, it will now look something like:", true
              player.output player.exit_message("north")
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(GaitHandler)
      end
    end
  end
end
