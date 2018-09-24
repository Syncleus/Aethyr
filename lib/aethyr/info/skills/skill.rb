require 'aethyr/render/text_util'
include TextUtil

module Skills
  class Skill
    attr_reader :name, :help_desc, :type, :xp, :owner, :id

    def initialize(owner, id, name, help_desc, type = :trait, xp = 0)
      @id = id
      @name = name
      @help_desc = help_desc
      @type = type
      @xp = xp
      @owner = owner
    end

    def add_xp amount
      @xp += amount
    end

    def level
      (@xp / 10000) + 1
    end

    def xp_so_far
      @xp % 10000
    end
    
    def xp_per_level
      10000
    end

    def xp_to_go
     10000 - xp_so_far
    end

    def level_percentage
      xp_so_far.to_f / 10000.0
    end
  end
  
  class << self
    def skills(event, player, room)
      box_width = 25
      box_work_width = box_width - 2
      width = player.word_wrap
      width = 200 if player.word_wrap.nil?
      boxes_per_row = width / box_width
      
      box_top = "┌" + ("─" * box_work_width) + "┐\n"
      box_bottom = "└" + ("─" * box_work_width) + "┘\n"
      
      output = ""
      text_format = "%-#{box_work_width}.#{box_work_width}s"
      text_format_right = "%#{box_work_width}.#{box_work_width}s"
      player.info.skills.each do |id, skill|
        
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
        
        output += "│#{generate_progress(box_work_width, skill.level_percentage)}│\n"
        
        xp_left = "#{skill.xp_to_go} xp to next"
        output += "│#{text_format_right % xp_left}│\n"
        
        xp_total = "#{skill.xp} xp total"
        output += "│#{text_format_right % xp_total}│\n"
        
        xp_frac = "#{skill.xp_so_far} / #{skill.xp_per_level} xp"
        output += "│#{text_format_right % xp_frac}│\n"

        output += box_bottom + "\n"
      end
      player.output(output)
    end
    
    private
    def generate_progress(width, percentage, style = :vertical_smooth)
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
  end
end