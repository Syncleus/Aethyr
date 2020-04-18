require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Acdoor
        class AcdoorHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["acdoor"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AcdoorHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acdoor\s+(\w+)$/i
              direction = $1
              acdoor({:direction => direction})
            when /^acdoor\s+(\w+)\s+(.*)$/i
              direction = $1.strip
              exit_room = $2.strip
              acdoor({:direction => direction, :exit_room => exit_room})
            when /^help (acdoor)$/i
              action_help_acdoor({})
            end
          end

          private
          def action_help_acdoor(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def acdoor event, player, room

            exit_room = nil
            if event[:exit_room].nil?
              out = find_object event[:direction], event
              if out and out.is_a? Exit
                exit_room = $manager.find out.exit_room
                other_side = $manager.find opposite_dir(event[:direction]), out.exit_room

                if other_side
                  $manager.delete_object other_side
                  player.output "Removed opposite exit (#{other_side})."
                else
                  player.output "Could not find opposite exit"
                end

                $manager.delete_object out
                player.output "Removed exit (#{out})."
              end
            else
              exit_room = $manager.get_object event[:exit_room]
            end

            if exit_room.nil?
              player.output "Cannot find #{event[:exit_room]} to connect to."
              return
            end

            door_here = $manager.create_object Door, room, nil, exit_room.goid, :@alt_names => [event[:direction]], :@name => "a door to the #{event[:direction]}"
            door_there = $manager.create_object Door, exit_room, nil, room.goid, :@alt_names => [opposite_dir(event[:direction])], :@name => "a door to the #{opposite_dir event[:direction]}"
            door_here.connect_to door_there

            player.output "Created: #{door_here}"
            player.output "Created: #{door_there}"

            if room
              event[:to_player] = "Frowning in concentration, you make vague motions with your hands. There is a small flash of light as #{door_here.name} to #{exit_room.name} appears."
              event[:to_other] = "Frowning in concentration, #{player.name} makes vague motions with #{player.pronoun(:possessive)} hands. There is a small flash of light as #{door_here.name} to #{exit_room.name} appears."
              room.out_event event
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcdoorHandler)
      end
    end
  end
end
