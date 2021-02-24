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
            event = @data
            room = $manager.get_object(@player.container)
            object = room.find(event[:to], Player)

            if object.nil?
              @player.output("To whom are you trying to whisper?")
              return
            elsif object == @player
              @player.output("Whispering to yourself again?")
              event[:to_other] = "#{@player.name} whispers to #{@player.pronoun(:reflexive)}."
              room.out_event(event, @player)
              return
            end

            phrase = event[:phrase]

            if phrase.nil?
              @player.ouput "What are you trying to whisper?"
              return
            end

            prefix = event[:pre]

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

            event[:target] = object
            event[:to_player] = prefix + "you whisper to #{object.name}#{phrase}"
            event[:to_target] = prefix + "#{@player.name} whispers to you#{phrase}"
            event[:to_other] = prefix + "#{@player.name} whispers quietly into #{object.name}'s ear."
            event[:to_other_blind] = "#{@player.name} whispers."
            event[:to_target_blind] = "Someone whispers to you#{phrase}"

            room.out_event(event)
          end
        end
      end
    end
  end
end
