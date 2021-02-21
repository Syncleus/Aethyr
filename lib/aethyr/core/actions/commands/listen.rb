require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Listen
        class ListenCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            room = $manager.get_object(@player.container)
            if event[:target].nil?
              event[:target] = room
              if room.info.sound
                event[:to_player] = "You listen carefully. #{room.info.sound}."
              else
                event[:to_player] = "You listen carefully but hear nothing unusual."
              end
              event[:to_other] = "A look of concentration forms on #{@player.name}'s face as #{@player.pronoun} listens intently."
              room.out_event event
              return
            end

            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              @player.output "Listening quietly, you can faintly hear your pulse."
              return
            elsif object.nil?
              @player.output "What would you like to listen to?"
              return
            end

            event[:target] = object
            event[:to_player] = "You bend your head towards #{object.name}. "
            if object.info.sound.nil? or object.info.sound == ""
              event[:to_player] << "#{object.pronoun.capitalize} emits no unusual sounds."
            else
              event[:to_player] << object.info.sound
            end
            event[:to_target] = "#{@player.name} listens to you carefully."
            event[:to_other] = "#{@player.name} bends #{@player.pronoun(:possessive)} head towards #{object.name} and listens."
            room.out_event event
          end
        end
      end
    end
  end
end
