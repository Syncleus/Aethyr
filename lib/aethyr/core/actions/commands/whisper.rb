require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Whisper
        class WhisperCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)
            object = room.find(self[:to], Player)

            if object.nil?
              self[:agent].output("To whom are you trying to whisper?")
              return
            elsif object == self[:agent]
              self[:agent].output("Whispering to yourself again?")
              self[:to_other] = "#{self[:agent].name} whispers to #{self[:agent].pronoun(:reflexive)}."
              room.out_event(event, self[:agent])
              return
            end

            phrase = self[:phrase]

            if phrase.nil?
              self[:agent].ouput "What are you trying to whisper?"
              return
            end

            prefix = self[:pre]

            if prefix
              prefix << ", "
            else
              prefix = ""
            end

            phrase[0,1] = phrase[0,1].capitalize

            last_char = phrase[-1..-1]

            unless ["!", "?", "."].include? last_char
              ender = "."
            end

            phrase = ", <say>\"#{phrase}#{ender}\"</say>"

            self[:target] = object
            self[:to_player] = prefix + "you whisper to #{object.name}#{phrase}"
            self[:to_target] = prefix + "#{self[:agent].name} whispers to you#{phrase}"
            self[:to_other] = prefix + "#{self[:agent].name} whispers quietly into #{object.name}'s ear."
            self[:to_other_blind] = "#{self[:agent].name} whispers."
            self[:to_target_blind] = "Someone whispers to you#{phrase}"

            room.out_event(event)
          end
        end
      end
    end
  end
end
