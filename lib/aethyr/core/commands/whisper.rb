require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Whisper
        class WhisperHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["whisper"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(WhisperHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^whisper\s+(\w+)\s+(\((.*?)\)\s*)?(.*)$/i
              action({ :to => $1, :phrase => $4, :pre => $3 })
            when /^help (whisper)$/i
              action_help({})
            end
          end

          private
          def action_help(event)
            @player.output <<'EOF'
Command: Whisper
Syntax: WHISPER [person] [message]

To communicate with someone in the same room, but privately, use this command.

Example:

whisper justin that dog needs a bath

Output:

You whisper to Justin, "That dog needs a bath."


See also: SAY
EOF
          end

          #Whispers to another thing.
          def action(event)
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

        Aethyr::Extend::HandlerRegistry.register_handler(WhisperHandler)
      end
    end
  end
end
