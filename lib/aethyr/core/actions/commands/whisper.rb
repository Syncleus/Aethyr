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
            
            room = $manager.get_object(@player.container)
            object = room.find(self[:to], Player)

            if object.nil?
              @player.output("To whom are you trying to whisper?")
              return
            elsif object == @player
              @player.output("Whispering to yourself again?")
              self[:to_other] = "#{@player.name} whispers to #{@player.pronoun(:reflexive)}."
              room.out_self(self, @player)
              return
            end

            phrase = self[:phrase]

            if phrase.nil?
              @player.ouput "What are you trying to whisper?"
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
            self[:to_target] = prefix + "#{@player.name} whispers to you#{phrase}"
            self[:to_other] = prefix + "#{@player.name} whispers quietly into #{object.name}'s ear."
            self[:to_other_blind] = "#{@player.name} whispers."
            self[:to_target_blind] = "Someone whispers to you#{phrase}"

            room.out_self(self)
          end
        end
      end
    end
  end
end
