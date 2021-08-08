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

            room = $manager.get_object(self[:agent].container)
            object = self[:agent].search_inv(self[:target]) || room.find(self[:target])

            if object == self[:agent] or self[:target] == "me"
              self[:agent].output "You covertly lick yourself.\nHmm, not bad."
              return
            elsif object.nil?
              self[:agent].output "What would you like to taste?"
              return
            end

            self[:target] = object
            self[:to_player] = "Sticking your tongue out hesitantly, you taste #{object.name}. "
            if object.info.taste.nil? or object.info.taste == ""
              self[:to_player] << "#{object.pronoun.capitalize} does not taste that great, but has no particular flavor."
            else
              self[:to_player] << object.info.taste
            end
            self[:to_target] = "#{self[:agent].name} licks you, apparently in an attempt to find out your flavor."
            self[:to_other] = "#{self[:agent].name} hesitantly sticks out #{self[:agent].pronoun(:possessive)} tongue and licks #{object.name}."
            room.out_event event
          end
        end
      end
    end
  end
end
