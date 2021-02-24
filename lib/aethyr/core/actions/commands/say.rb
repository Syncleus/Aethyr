require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Say
        class SayCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data.dup
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
      end
    end
  end
end
