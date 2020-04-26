require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Adesc
        class AdescHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "adesc"
            see_also = nil
            syntax_formats = ["ADESC [OBJECT] [DESCRIPTION]", "ADESC INROOM [OBJECT] [DESCRIPTION]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["adesc"], help_entries: AdescHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^adesc\s+inroom\s+(.*?)\s+(.*)$/i
              object = $1
              inroom = true
              desc = $2
              adesc({:object => object, :inroom => inroom, :desc => desc})
            when /^adesc\s+(.*?)\s+(.*)$/i
              object = $1
              desc = $2
              adesc({:object => object, :desc => desc})
            end
          end

          private
          def adesc(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = nil
            if event[:object].downcase == "here"
              object = room
            else
              object = find_object(event[:object], event)
            end

            if object.nil?
              player.output "Cannot find #{event[:object]}."
              return
            end

            if event[:inroom]
              if event[:desc].nil? or event[:desc].downcase == "false"
                object.show_in_look = false
                player.output "#{object.name} will not be shown in the room description."
              else
                object.show_in_look= event[:desc]
                player.output "The room will show #{object.show_in_look}"
              end
            else
              object.instance_variable_set(:@short_desc, event[:desc])
              player.output "#{object.name} now looks like:\n#{object.short_desc}"
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AdescHandler)
      end
    end
  end
end
