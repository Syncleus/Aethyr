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
          
          private

          def self.generate_progress(width, percentage, style = :vertical_smooth)
            if (style.eql? :horizontal_smooth) or (style.eql? :vertical_smooth)
              working_space = width - 7
              block_per = 1.0 / working_space.to_f
              filled = (working_space * percentage).to_i
              filled_coverage = filled.to_f * block_per
              bar = ("█" * filled).to_s

              remaining_coverage = percentage - filled_coverage
              percent_of_block = remaining_coverage / block_per
              if percent_of_block >= (7.0 / 8.0)
                bar += (style.eql?(:horizontal_smooth) ? "▉" : "▇" )
              elsif percent_of_block >= (6.0 / 8.0)
                bar += (style.eql?(:horizontal_smooth) ? "▊" : "▆" )
              elsif percent_of_block >= (5.0 / 8.0)
                bar += (style.eql?(:horizontal_smooth) ? "▋" : "▅" )
              elsif percent_of_block >= (4.0 / 8.0)
                bar += (style.eql?(:horizontal_smooth) ? "▌" : "▄" )
              elsif percent_of_block >= (3.0 / 8.0)
                bar += (style.eql?(:horizontal_smooth) ? "▍" : "▃" )
              elsif percent_of_block >= (2.0 / 8.0)
                bar += (style.eql?(:horizontal_smooth) ? "▎" : "▂" )
              elsif percent_of_block >= (1.0 / 8.0)
                bar += (style.eql?(:horizontal_smooth) ? "▏" : "▁" )
              end

              bar_format = "%-#{working_space}.#{working_space}s"
              percent_format = "%-4.4s"
              percent_text = (percentage * 100.0).to_i.to_s + "%"

              return "[<raw fg:white>#{bar_format % bar}</raw fg:white>] #{percent_format % percent_text}"
            end
          end

          Aethyr::Extend::HandlerRegistry.register_handler(SkillsHandler)
        end
      end
    end
  end
end