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
            event = @data
            room = $manager.get_object(@player.container)
            object = @player.search_inv(event[:target]) || room.find(event[:target])

            if object == @player or event[:target] == "me"
              @player.output "You feel fine."
              return
            elsif object.nil?
              @player.output "What would you like to feel?"
              return
            end

            event[:target] = object
            event[:to_player] = "You reach out your hand and gingerly feel #{object.name}. "
            if object.info.texture.nil? or object.info.texture == ""
              event[:to_player] << "#{object.pronoun(:possessive).capitalize} texture is what you would expect."
            else
              event[:to_player] << object.info.texture
            end
            event[:to_target] = "#{@player.name} reaches out a hand and gingerly touches you."
            event[:to_other] = "#{@player.name} reaches out #{@player.pronoun(:possessive)} hand and touches #{object.name}."
            room.out_event event
          end
        end
      end
    end
  end
end
