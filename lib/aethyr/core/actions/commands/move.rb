require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Move
        class MoveCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data.dup
            room = $manager.get_object(@player.container)
            exit = room.exit(event[:direction])

            if exit.nil?
              @player.output("You cannot go #{event[:direction]}.")
              return
            elsif exit.can? :open and not exit.open?
              @player.output("That exit is closed. Perhaps you should open it?")
              return
            end

            new_room = $manager.find(exit.exit_room)

            if new_room.nil?
              @player.output("That exit #{exit.name} leads into the void.")
              return
            end

            room.remove(@player)
            new_room.add(@player)
            @player.container = new_room.game_object_id
            event[:to_player] = "You move #{event[:direction]}."
            event[:to_other] = "#{@player.name} leaves #{event[:direction]}."
            event[:to_blind_other] = "You hear someone leave."

            room.out_event(event)
            look_text = new_room.look(@player)
            out_text = Window.split_message(look_text, 79).join("\n")
            @player.output(out_text, message_type: :look, internal_clear: true)
          end
        end
      end
    end
  end
end
