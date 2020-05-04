require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Gait
        class GaitHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "gait"
            see_also = nil
            syntax_formats = ["GAIT"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["gait"], help_entries: GaitHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^gait(\s+(.*))?$/i
              phrase = $2 if $2
              gait({:phrase => phrase})
            end
          end

          private
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
