require "aethyr/core/actions/commands/skills"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"
require 'aethyr/core/render/text_util'
include TextUtil

module Aethyr
  module Core
    module Commands
      module Skills
        class SkillsHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "skills"
            see_also = nil
            syntax_formats = ["SKILLS"]
            aliases = nil
            content =  <<'EOF'
List all your currently known skills, their level, and level up info.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["skills"], help_entries: SkillsHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^skills$/i
              $manager.submit_action(Aethyr::Core::Actions::Skills::SkillsCommand.new(@player, {}))
            end
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(SkillsHandler)
      end
    end
  end
end
