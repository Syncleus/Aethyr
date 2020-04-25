require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Get
        class GetHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "get"
            see_also = ["GIVE"]
            syntax_formats = ["GET [object]", "GRAB [object'", "TAKE [object]"]
            aliases = ["grab", "take"]
            content =  <<'EOF'
Pick up an object and put it in your inventory.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["get", "grab", "take"], GetHandler.create_help_entries)
          end
          
          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(get|grab|take)\s+((\w+|\s)*)(\s+from\s+(\w+))/i
              action({ :object => $2.strip, :from => $5 })
            when /^(get|grab|take)\s+(.*)$/i
              action({ :object => $2.strip })
            end
          end
          
          private
          
          #Gets (or takes) an object and puts it in the player's inventory.
          def action(event)
            room = $manager.get_object(@player.container)
            if event[:from].nil?
              object = $manager.find(event[:object], room)

              if object.nil?
                @player.output("There is no #{event[:object]} to take.")
                return
              elsif not object.movable
                @player.output("You cannot take #{object.name}.")
                return
              elsif @player.inventory.full?
                @player.output("You cannot hold any more objects.")
                return
              end

              room.remove(object)
              object.container = @player.goid
              @player.inventory << object

              event[:to_player] = "You take #{object.name}."
              event[:to_other] = "#{@player.name} takes #{object.name}."
              room.out_event(event)
            else
              from = event[:from]
              container = $manager.find(from, room)
              @player.inventory.find(from) if container.nil?

              if container.nil?
                @player.output("There is no #{from}.")
                return
              elsif not container.is_a? Container
                @player.output("Not sure how to do that.")
                return
              elsif container.can? :open and container.closed?
                @player.output("You will need to open it first.")
                return
              end

              object = $manager.find(event[:object], container)

              if object.nil?
                @player.output("There is no #{event[:object]} in the #{container.name}.")
                return
              elsif not object.movable
                @player.output("You cannot take the #{object.name}.")
                return
              elsif @player.inventory.full?
                @player.output("You cannot hold any more objects.")
                return
              end

              container.remove(object)
              @player.inventory.add(object)

              event[:to_player] = "You take #{object.name} from #{container.name}."
              event[:to_other] = "#{@player.name} takes #{object.name} from #{container.name}."
              room.out_event(event)
            end
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(GetHandler)
      end
    end
  end
end