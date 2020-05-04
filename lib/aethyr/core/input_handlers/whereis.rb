require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

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
              whereis({:object => object})
            end
          end

          private
          def whereis(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:object], event)

            if object.nil?
              player.output "Could not find #{event[:object]}."
              return
            end

            if object.container.nil?
              if object.can? :area and not object.area.nil? and object.area != object
                area = $manager.get_object object.area || "nothing"
                player.output "#{object} is in #{area}."
              else
                player.output "#{object} is not in anything."
              end
            else
              container = $manager.get_object object.container
              if container.nil?
                player.output "Container for #{object} not found."
              else
                player.output "#{object} is in #{container}."
                event[:object] = container.goid
                whereis(event, player, room)
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(WhereisHandler)
      end
    end
  end
end