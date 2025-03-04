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
            
            room = $manager.get_object(@player.container)
            if self[:target].nil?
              self[:target] = room
              if room.info.sound
                self[:to_player] = "You listen carefully. #{room.info.sound}."
              else
                self[:to_player] = "You listen carefully but hear nothing unusual."
              end
              self[:to_other] = "A look of concentration forms on #{@player.name}'s face as #{@player.pronoun} listens intently."
              room.out_self self
              return
            end

            object = @player.search_inv(self[:target]) || room.find(self[:target])

            if object == @player or self[:target] == "me"
              @player.output "Listening quietly, you can faintly hear your pulse."
              return
            elsif object.nil?
              @player.output "What would you like to listen to?"
              return
            end

            self[:target] = object
            self[:to_player] = "You bend your head towards #{object.name}. "
            if object.info.sound.nil? or object.info.sound == ""
              self[:to_player] << "#{object.pronoun.capitalize} emits no unusual sounds."
            else
              self[:to_player] << object.info.sound
            end
            self[:to_target] = "#{@player.name} listens to you carefully."
            self[:to_other] = "#{@player.name} bends #{@player.pronoun(:possessive)} head towards #{object.name} and listens."
            room.out_self self
          end
        end
      end
    end
  end
end
