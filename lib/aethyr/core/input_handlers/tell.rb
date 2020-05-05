require "aethyr/core/actions/commands/reply"
require "aethyr/core/actions/commands/tell"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Tell
        class TellHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "tell"
            see_also = ["SAY", "SAYTO", "WHISPER", "REPLY"]
            syntax_formats = ["TELL [player] [message]"]
            aliases = nil
            content =  <<'EOF'
All inhabitants of Aethyr have the ability to communicate privately with each other over long distances. This is done through the TELL command. Those who investigate these kinds of things claim there is some kind of latent telepathy in all of us. However, while no one knows for certain how it works, everyone knows it does.

Example:
TELL Justin Hey, how's it going?

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))



            command = "reply"
            see_also = ["TELL"]
            syntax_formats = ["REPLY [message]"]
            aliases = nil
            content =  <<'EOF'
Reply is a shortcut to send a tell to the last person who sent you a tell.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["tell", "reply"], help_entries: TellHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^tell\s+(\w+)\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Tell::TellCommand.new(@player, {:target => $1, :message => $2 }))
            when /^reply\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Reply::ReplyCommand.new(@player, {:message => $1 }))
            end
          end

          private

          #Tells someone something.


        end

        Aethyr::Extend::HandlerRegistry.register_handler(TellHandler)
      end
    end
  end
end
