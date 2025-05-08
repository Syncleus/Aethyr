require "aethyr/core/actions/commands/unlock"
require "aethyr/core/actions/commands/lock"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Locking
        class LockingHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "locking"
            see_also = ["OPEN", "CLOSE"]
            syntax_formats = ["LOCK [object or direction]", "UNLOCK [object or direction]"]
            aliases = ["lock", "unlock"]
            content =  <<'EOF'
Lock or unlock the given object, if you have a key for it.

Note that you can lock a door while it is open, then close it.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["lock", "unlock"], help_entries: LockingHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^lock\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Lock::LockCommand.new(@player,  :object => $1 ))
            when /^unlock\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Unlock::UnlockCommand.new(@player,  :object => $1 ))
            end
          end

          private


        end
        
        Aethyr::Extend::HandlerRegistry.register_handler(LockingHandler)
      end
    end
  end
end