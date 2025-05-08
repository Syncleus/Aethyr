require "aethyr/core/actions/commands/say"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Say
        class SayHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "say"
            see_also = ["WHISPER", "SAYTO"]
            syntax_formats = ["SAY [message]"]
            aliases = nil
            content =  <<'EOF'
This is the basic command for communication.  Everyone in the room hears what you say.
Some formatting is automatic, and a few emoticons are supported at the end of the command.

Example: say i like cheese
Output:  You say, "I like cheese."

Example: say i like cheese! :)
Output:  You smile and exclaim, "I like cheese!"

You can also specify a prefix in parentheses after the say command.

Example: say (in trepidation) are you going to take my cheese?
Output:  In trepidation, you ask, "Are you going to take my cheese?"

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "sayto"
            see_also = ["WHISPER", "SAY"]
            syntax_formats = ["SAYTO [name] [message]"]
            aliases = nil
            content =  <<'EOF'
Say something to someone in particular, who is in the same room:

Example:

sayto bob i like cheese

Output:

You say to Bob, "I like cheese."

Also supports the same variations as the SAY command.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["say", "sayto"], help_entries: SayHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^say\s+(\((.*?)\)\s*)?(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Say::SayCommand.new(@player,  :phrase => $3, :pre => $2 ))
            when /^sayto\s+(\w+)\s+(\((.*?)\)\s*)?(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Say::SayCommand.new(@player, :target => $1, :phrase => $4, :pre => $3 ))
            end
          end

          private

          #Says something to the room or to a specific player.

        end

        Aethyr::Extend::HandlerRegistry.register_handler(SayHandler)
      end
    end
  end
end
