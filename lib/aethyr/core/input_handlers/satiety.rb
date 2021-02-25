
require "aethyr/core/actions/commands/satiety"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Satiety
        class SatietyHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "satiety"
            see_also = ["STAT", "HEALTH"]
            syntax_formats = ["HUNGER", "SATIETY"]
            aliases = ["hunger"]
            content =  <<'EOF'
Shows you how hungry you are.

You can be:
	completely stuffed
	full and happy
	full and happy
	satisfied
	not hungry
	slightly hungry
	slightly hungry
	peckish
	hungry
	very hungry
	famished
	starving
	literally dying of hunger

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["hunger", "satiety"], help_entries: SatietyHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(satiety|hunger)$/i
              $manager.submit_action(Aethyr::Core::Actions::Satiety::SatietyCommand.new(@player, {}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(SatietyHandler)
      end
    end
  end
end
