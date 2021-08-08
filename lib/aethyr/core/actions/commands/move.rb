require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Move
        class MoveCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            room = $manager.get_object(self[:agent].container)
            exit = room.exit(self[:direction])

            if exit.nil?
              self[:agent].output("You cannot go #{self[:direction]}.")
              return
            elsif exit.can? :open and not exit.open?
              self[:agent].output("That exit is closed. Perhaps you should open it?")
              return
            end

            new_room = $manager.find(exit.exit_room)

            if new_room.nil?
              self[:agent].output("That exit #{exit.name} leads into the void.")
              return
            end

            room.remove(self[:agent])
            new_room.add(self[:agent])
            self[:agent].container = new_room.game_object_id
            room_out_data = {}
            room_out_data[:player] = self[:agent]
            room_out_data[:to_player] = "You move #{self[:direction]}."
            room_out_data[:to_other] = "#{self[:agent].name} leaves #{self[:direction]}."
            room_out_data[:to_blind_other] = "You hear someone leave."
            room_out_event = Event.new(room_out_data)

            room.out_event(room_out_event)
            look_text = new_room.look(self[:agent])
            out_text = Window.split_message(look_text, 79).join("\n")
            self[:agent].output(out_text, message_type: :look, internal_clear: true)
          end
        end
      end
    end
  end
end
