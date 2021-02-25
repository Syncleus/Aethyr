require "aethyr/core/actions/commands/health"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Health
        class HealthHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "health"
            see_also = ["STATUS", "HUNGER"]
            syntax_formats = ["HEALTH"]
            aliases = nil
            content =  <<'EOF'
Shows you how healthy you are.

You can be:
	at full health
	a bit bruised
	a little beat up
	slightly injured
	quite injured
	slightly wounded
	wounded in several places
	heavily wounded
	bleeding profusely and in serious pain
	nearly dead
	dead

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["health"], help_entries: HealthHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(health)$/i
              $manager.submit_action(Aethyr::Core::Actions::Health::HealthCommand.new(@player, {}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(HealthHandler)
      end
    end
  end
end
