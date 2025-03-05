require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Taste
        class TasteCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            room = $manager.get_object(@player.container)
            object = @player.search_inv(self[:target]) || room.find(self[:target])

            if object == @player or self[:target] == "me"
              @player.output "You covertly lick yourself.\nHmm, not bad."
              return
            elsif object.nil?
              @player.output "What would you like to taste?"
              return
            end

            self[:target] = object
            self[:to_player] = "Sticking your tongue out hesitantly, you taste #{object.name}. "
            if object.info.taste.nil? or object.info.taste == ""
              self[:to_player] << "#{object.pronoun.capitalize} does not taste that great, but has no particular flavor."
            else
              self[:to_player] << object.info.taste
            end
            self[:to_target] = "#{@player.name} licks you, apparently in an attempt to find out your flavor."
            self[:to_other] = "#{@player.name} hesitantly sticks out #{@player.pronoun(:possessive)} tongue and licks #{object.name}."
            room.out_event self
          end
        end
      end
    end
  end
end
