require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Listen
        class ListenCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)
            if self[:target].nil?
              self[:target] = room
              if room.info.sound
                self[:to_player] = "You listen carefully. #{room.info.sound}."
              else
                self[:to_player] = "You listen carefully but hear nothing unusual."
              end
              self[:to_other] = "A look of concentration forms on #{self[:agent].name}'s face as #{self[:agent].pronoun} listens intently."
              room.out_event event
              return
            end

            object = self[:agent].search_inv(self[:target]) || room.find(self[:target])

            if object == self[:agent] or self[:target] == "me"
              self[:agent].output "Listening quietly, you can faintly hear your pulse."
              return
            elsif object.nil?
              self[:agent].output "What would you like to listen to?"
              return
            end

            self[:target] = object
            self[:to_player] = "You bend your head towards #{object.name}. "
            if object.info.sound.nil? or object.info.sound == ""
              self[:to_player] << "#{object.pronoun.capitalize} emits no unusual sounds."
            else
              self[:to_player] << object.info.sound
            end
            self[:to_target] = "#{self[:agent].name} listens to you carefully."
            self[:to_other] = "#{self[:agent].name} bends #{self[:agent].pronoun(:possessive)} head towards #{object.name} and listens."
            room.out_event event
          end
        end
      end
    end
  end
end
