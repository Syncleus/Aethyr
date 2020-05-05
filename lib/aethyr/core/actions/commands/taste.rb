require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Taste
        class TasteCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            room = $manager.get_object(@player.container)
            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              @player.output "You covertly lick yourself.\nHmm, not bad."
              return
            elsif object.nil?
              @player.output "What would you like to taste?"
              return
            end

            event[:target] = object
            event[:to_player] = "Sticking your tongue out hesitantly, you taste #{object.name}. "
            if object.info.taste.nil? or object.info.taste == ""
              event[:to_player] << "#{object.pronoun.capitalize} does not taste that great, but has no particular flavor."
            else
              event[:to_player] << object.info.taste
            end
            event[:to_target] = "#{@player.name} licks you, apparently in an attempt to find out your flavor."
            event[:to_other] = "#{@player.name} hesitantly sticks out #{@player.pronoun(:possessive)} tongue and licks #{object.name}."
            room.out_event event
          end
        end
      end
    end
  end
end
