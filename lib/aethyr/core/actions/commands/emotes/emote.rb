require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Emote
        class EmoteCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            action = event[:show].strip

            unless ['!', '.', '?', '"'].include? action[-1..-1]
              action << '.'
            end

            if action =~ /\$me[^a-zA-Z]/i
              action.gsub!(/\$me/i, player.name)
              action[0,1] = action[0,1].capitalize
              show = action
            elsif action.include? '$'
              people = []
              action.gsub!(/\$(\w+)/) do |name|
                target = room.find($1)
                people << target unless target.nil?
                target ? target.name : 'no one'
              end

              people.each do |person|
                out = action.gsub(person.name, 'you')
                person.output("#{player.name} #{out}", message_type = :chat) unless person.can? :blind and person.blind?
              end

              room.output("#{player.name} #{action}", player, *people)
              player.output("You emote: #{player.name} #{action}")
            else
              show = "#{player.name} #{action}"
            end

            if show
              event[:message_type] = :chat
              event[:to_player] = "You emote: #{show}"
              event[:to_other] = show
              room.out_event event
            end
          end

        end
      end
    end
  end
end
