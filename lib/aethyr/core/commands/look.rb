require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Look
        class LookHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["l", "look"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(l|look)$/i
              action({})
            when /^(l|look)\s+(in|inside)\s+(.*)$/i
              action({ :in => $3 })
            when /^(l|look)\s+(.*)$/i
              action({ :at => $2 })
            when /^help (l|look)$/i
              action_help({})
            end
          end

          private
          def action_help(event)
            @player.output <<'EOF'
Command: Look
Syntax: LOOK
Syntax: LOOK [object]
Syntax: LOOK IN [object]

Look by itself will show you your surroundings.

Look followed by an object will look at that object.

Look IN will look inside of a container (if it is open).

'l' is a shortcut for look.
EOF
          end

          def action(event)
            room = $manager.get_object(@player.container)
            if @player.blind?
              @player.output "You cannot see while you are blind."
            else
              if event[:at]
                object = room if event[:at] == "here"
                object = object || @player.search_inv(event[:at]) || room.find(event[:at])

                if object.nil?
                  @player.output("Look at what, again?")
                  return
                end

                if object.is_a? Exit
                  @player.output object.peer
                elsif object.is_a? Room
                  @player.output("You are indoors.", true) if object.info.terrain.indoors
                  @player.output("You are underwater.", true) if object.info.terrain.underwater
                  @player.output("You are swimming.", true) if object.info.terrain.water

                  @player.output "You are in a place called #{room.name} in #{room.area ? room.area.name : "an unknown area"}.", true
                  if room.area
                    @player.output "The area is generally #{describe_area(room.area)} and this spot is #{describe_area(room)}."
                  elsif room.info.terrain.room_type
                    @player.output "Where you are standing is considered to be #{describe_area(room)}."
                  else
                    @player.output "You are unsure about anything else concerning the area."
                  end
                elsif @player == object
                  @player.output "You look over yourself and see:\n#{@player.instance_variable_get("@long_desc")}", true
                  @player.output object.show_inventory
                else
                  @player.output object.long_desc
                end
              elsif event[:in]
                object = room.find(event[:in])
                object = @player.inventory.find(event[:in]) if object.nil?

                if object.nil?
                  @player.output("Look inside what?")
                elsif not object.can? :look_inside
                  @player.output("You cannot look inside that.")
                else
                  object.look_inside(event)
                end
              else
                if not room.nil?
                  look_text = room.look(@player)
                  @player.output(look_text)
                else
                  @player.output "Nothing to look at."
                end
              end
            end
          end

          def describe_area(object)
            if object.is_a? Room
              result = object.terrain_type.room_text unless object.terrain_type.nil?
              result = "uncertain" if result.nil?
            elsif object.is_a? Area
              result = object.terrain_type.area_text unless object.terrain_type.nil?
              result = "uncertain" if result.nil?
            end
            result
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(LookHandler)
      end
    end
  end
end
