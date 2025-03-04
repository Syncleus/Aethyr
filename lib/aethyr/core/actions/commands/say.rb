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
            room = $manager.get_object(@player.container)

            phrase = self[:phrase]
            target = self[:target] && room.find(self[:target])
            prefix = self[:pre]

            if prefix
              prefix << ", "
            else
              prefix = ""
            end

            if phrase.nil?
              @player.output("Huh?")
              return
            elsif self[:target] and target.nil?
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

            self[:message_type] = :chat
            self[:target] = target
            if target and pvoice == "ask"
              self[:to_target] = prefix + "#{@player.name} #{rvoice} you, #{phrase}"
              self[:to_player] = prefix + "you #{pvoice} #{target.name}, #{phrase}"
              self[:to_other] = prefix + "#{@player.name} #{rvoice} #{target.name}, #{phrase}"
              self[:to_blind_target] = "Someone asks, #{phrase}"
              self[:to_blind_other] = "Someone asks, #{phrase}"
              self[:to_deaf_target] = "#{@player.name} seems to be asking you something."
              self[:to_deaf_other] = "#{@player.name} seems to be asking #{target.name} something."
            elsif target
              self[:to_target] = prefix + "#{@player.name} #{rvoice} to you, #{phrase}"
              self[:to_player] = prefix + "you #{pvoice} to #{target.name}, #{phrase}"
              self[:to_other] = prefix + "#{@player.name} #{rvoice} to #{target.name}, #{phrase}"
              self[:to_blind_target] = "Someone #{rvoice}, #{phrase}"
              self[:to_blind_other] = "Someone #{rvoice}, #{phrase}"
              self[:to_deaf_target] = "You see #{@player.name} say something to you."
              self[:to_deaf_other] = "You see #{@player.name} say something to #{target.name}."
            else
              self[:to_player] = prefix + "you #{pvoice}, #{phrase}"
              self[:to_other] = prefix + "#{@player.name} #{rvoice}, #{phrase}"
              self[:to_blind_other] = "Someone #{rvoice}, #{phrase}"
              self[:to_deaf_target] = "You see #{@player.name} say something."
              self[:to_deaf_other] = "You see #{@player.name} say something."
            end

            room.out_self(self)
          end
        end
      end
    end
  end
end
