require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Skills
        class SkillsCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
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
        end
      end
    end
  end
end
