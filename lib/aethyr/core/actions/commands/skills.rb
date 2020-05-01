require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"
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
              action({})
            end
          end
          
          private
          def action(event)
            box_width = 25
            box_work_width = box_width - 2
            width = @player.word_wrap
            width = 200 if @player.word_wrap.nil?
            boxes_per_row = width / box_width

            box_top = "┌" + ("─" * box_work_width) + "┐\n"
            box_bottom = "└" + ("─" * box_work_width) + "┘\n"

            output = ""
            text_format = "%-#{box_work_width}.#{box_work_width}s"
            text_format_right = "%#{box_work_width}.#{box_work_width}s"
            @player.info.skills.each do |id, skill|

              output += box_top

              level_width = box_work_width - skill.name.length
              level_format = "%#{level_width}.#{level_width}s"
              level = "lv #{skill.level}"
              title = "#{skill.name}#{level_format % level}"
              output += "│<raw fg:white>#{title}</raw fg:white>│\n"

              desc_lines = wrap(skill.help_desc, box_work_width)
              desc_lines.each do |line|
                output += "│#{text_format % line}│\n"
              end

              output += "│#{text_format_right % ''}│\n"

              output += "│#{SkillsHandler::generate_progress(box_work_width, skill.level_percentage)}│\n"

              xp_left = "#{skill.xp_to_go} xp to next"
              output += "│#{text_format_right % xp_left}│\n"

              xp_total = "#{skill.xp} xp total"
              output += "│#{text_format_right % xp_total}│\n"

              xp_frac = "#{skill.xp_so_far} / #{skill.xp_per_level} xp"
              output += "│#{text_format_right % xp_frac}│\n"

              output += box_bottom + "\n"
            end
            @player.output(output)
          end
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