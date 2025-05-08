require "aethyr/core/actions/commands/whisper"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Whisper
        class WhisperHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "whisper"
            see_also = ["SAY"]
            syntax_formats = ["WHISPER [person] [message]"]
            aliases = nil
            content =  <<'EOF'
To communicate with someone in the same room, but privately, use this command.

Example:

whisper justin that dog needs a bath

Output:

You whisper to Justin, "That dog needs a bath."

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["whisper"], help_entries: WhisperHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^whisper\s+(\w+)\s+(\((.*?)\)\s*)?(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Whisper::WhisperCommand.new(@player,  :to => $1, :phrase => $4, :pre => $3 ))
            end
          end

          private
          #Whispers to another thing.

        end

        Aethyr::Extend::HandlerRegistry.register_handler(WhisperHandler)
      end
    end
  end
end
