require "aethyr/core/actions/commands/whereis"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Whereis
        class WhereisHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "whereis"
            see_also = nil
            syntax_formats = ["WHEREIS"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["whereis"], help_entries: WhereisHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^whereis\s(.*)$/
              object = $1
              $manager.submit_action(Aethyr::Core::Actions::Whereis::WhereisCommand.new(@player, {:object => object}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(WhereisHandler)
      end
    end
  end
end
