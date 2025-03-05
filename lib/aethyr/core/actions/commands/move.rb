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
            room = $manager.get_object(@player.container)
            exit = room.exit(self[:direction])

            if exit.nil?
              @player.output("You cannot go #{self[:direction]}.")
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
            self[:to_player] = "You move #{self[:direction]}."
            self[:to_other] = "#{@player.name} leaves #{self[:direction]}."
            self[:to_blind_other] = "You hear someone leave."

            room.out_event(self)
            look_text = new_room.look(@player)
            out_text = Window.split_message(look_text, 79).join("\n")
            @player.output(out_text, message_type: :look, internal_clear: true)
          end
        end
      end
    end
  end
end
