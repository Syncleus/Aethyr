require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Say
        class SayHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["say", "sayto"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(SayHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^say\s+(\((.*?)\)\s*)?(.*)$/i
              action({ :phrase => $3, :pre => $2 })
            when /^sayto\s+(\w+)\s+(\((.*?)\)\s*)?(.*)$/i
              action({:target => $1, :phrase => $4, :pre => $3 })
            when /^help (sayto)$/i
              action_help_sayto({})
            when /^help (say)$/i
              action_help_say({})
            end
          end

          private
          def action_help_say(event)
            @player.output <<'EOF'
Command: Say
Syntax: SAY [message]

This is the basic command for communication.  Everyone in the room hears what you say.
Some formatting is automatic, and a few emoticons are supported at the end of the command.

Example: say i like cheese
Output:  You say, "I like cheese."

Example: say i like cheese! :)
Output:  You smile and exclaim, "I like cheese!"

You can also specify a prefix in parentheses after the say command.

Example: say (in trepidation) are you going to take my cheese?
Output:  In trepidation, you ask, "Are you going to take my cheese?"

See also: WHISPER, SAYTO
EOF
          end

          def action_help_sayto(event)
            @player.output <<'EOF'
Command: Say to
Syntax: SAYTO [name] [message]

Say something to someone in particular, who is in the same room:

Example:

sayto bob i like cheese

Output:

You say to Bob, "I like cheese."

Also supports the same variations as the SAY command.

See also: WHISPER, SAY
EOF
          end

          #Says something to the room or to a specific player.
          def action(event)
            room = $manager.get_object(@player.container)

            phrase = event[:phrase]
            target = event[:target] && room.find(event[:target])
            prefix = event[:pre]

            if prefix
              prefix << ", "
            else
              prefix = ""
            end

            if phrase.nil?
              @player.output("Huh?")
              return
            elsif event[:target] and target.nil?
              @player.output("Say what to whom?")
              return
            elsif target and target == @player
              @player.output "Talking to yourself again?"
              return
            elsif target
              to_clause = " to #{target.name}"
              ask_clause = " #{target.name}"
            else
              to_clause = ""
              ask_clause = ""
            end

            phrase[0,1] = phrase[0,1].capitalize
            phrase.gsub!(/(\s|^|\W)(i)(\s|$|\W)/) { |match| match.sub('i', 'I') }

            case phrase
            when /:\)$/
              rvoice = "smiles and "
              pvoice = "smile and "
            when /:\($/
              rvoice = "frowns and "
              pvoice = "frown and "
            when /:D$/
              rvoice = "laughs as #{@player.pronoun} "
              pvoice = "laugh as you "
            else
              rvoice = ""
              pvoice = ""
            end

            phrase = phrase.gsub(/\s*(:\)|:\()|:D/, '').strip.gsub(/\s{2,}/, ' ')

            case phrase[-1..-1]
            when "!"
              pvoice += "exclaim"
              rvoice += "exclaims"
            when "?"
              pvoice += "ask"
              rvoice += "asks"
            when "."
              pvoice += "say"
              rvoice += "says"
            else
              pvoice += "say"
              rvoice += "says"
              ender = "."
            end

            phrase = "<say>\"#{phrase}#{ender}\"</say>"

            event[:message_type] = :chat
            event[:target] = target
            if target and pvoice == "ask"
              event[:to_target] = prefix + "#{@player.name} #{rvoice} you, #{phrase}"
              event[:to_player] = prefix + "you #{pvoice} #{target.name}, #{phrase}"
              event[:to_other] = prefix + "#{@player.name} #{rvoice} #{target.name}, #{phrase}"
              event[:to_blind_target] = "Someone asks, #{phrase}"
              event[:to_blind_other] = "Someone asks, #{phrase}"
              event[:to_deaf_target] = "#{@player.name} seems to be asking you something."
              event[:to_deaf_other] = "#{@player.name} seems to be asking #{target.name} something."
            elsif target
              event[:to_target] = prefix + "#{@player.name} #{rvoice} to you, #{phrase}"
              event[:to_player] = prefix + "you #{pvoice} to #{target.name}, #{phrase}"
              event[:to_other] = prefix + "#{@player.name} #{rvoice} to #{target.name}, #{phrase}"
              event[:to_blind_target] = "Someone #{rvoice}, #{phrase}"
              event[:to_blind_other] = "Someone #{rvoice}, #{phrase}"
              event[:to_deaf_target] = "You see #{@player.name} say something to you."
              event[:to_deaf_other] = "You see #{@player.name} say something to #{target.name}."
            else
              event[:to_player] = prefix + "you #{pvoice}, #{phrase}"
              event[:to_other] = prefix + "#{@player.name} #{rvoice}, #{phrase}"
              event[:to_blind_other] = "Someone #{rvoice}, #{phrase}"
              event[:to_deaf_target] = "You see #{@player.name} say something."
              event[:to_deaf_other] = "You see #{@player.name} say something."
            end

            room.out_event(event)
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(SayHandler)
      end
    end
  end
end
