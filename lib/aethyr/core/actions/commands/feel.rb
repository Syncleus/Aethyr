require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Feel
        class FeelCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)
            object = self[:agent].search_inv(self[:target]) || room.find(self[:target])

            if object == self[:agent] or self[:target] == "me"
              self[:agent].output "You feel fine."
              return
            elsif object.nil?
              self[:agent].output "What would you like to feel?"
              return
            end

            self[:target] = object
            self[:to_player] = "You reach out your hand and gingerly feel #{object.name}. "
            if object.info.texture.nil? or object.info.texture == ""
              self[:to_player] << "#{object.pronoun(:possessive).capitalize} texture is what you would expect."
            else
              self[:to_player] << object.info.texture
            end
            self[:to_target] = "#{self[:agent].name} reaches out a hand and gingerly touches you."
            self[:to_other] = "#{self[:agent].name} reaches out #{self[:agent].pronoun(:possessive)} hand and touches #{object.name}."
            room.out_event event
          end
        end
      end
    end
  end
end
