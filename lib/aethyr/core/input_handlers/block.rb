require "aethyr/core/actions/commands/simple_block"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Block
        class BlockHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "block"
            see_also = ["THRUST", "STATUS"]
            syntax_formats = ["BLOCK <target>", "BLOCK"]
            aliases = nil
            content =  <<'EOF'
This is a simple block which uses your weapon to attempt to block an opponent's attack. If you are not wielding a weapon, you will attempt a block with your bare hands.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["block"], help_entries: BlockHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^block(\s+(.*))?$/i
              target = $2
              $manager.submit_action(Aethyr::Core::Actions::SimpleBlock::SimpleBlockCommand.new(@player, :target => target))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(BlockHandler)
      end
    end
  end
end
