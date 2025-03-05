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
            
            room = $manager.get_object(@player.container)
            object = @player.search_inv(self[:target]) || room.find(self[:target])

            if object == @player or self[:target] == "me"
              @player.output "You feel fine."
              return
            elsif object.nil?
              @player.output "What would you like to feel?"
              return
            end

            self[:target] = object
            self[:to_player] = "You reach out your hand and gingerly feel #{object.name}. "
            if object.info.texture.nil? or object.info.texture == ""
              self[:to_player] << "#{object.pronoun(:possessive).capitalize} texture is what you would expect."
            else
              self[:to_player] << object.info.texture
            end
            self[:to_target] = "#{@player.name} reaches out a hand and gingerly touches you."
            self[:to_other] = "#{@player.name} reaches out #{@player.pronoun(:possessive)} hand and touches #{object.name}."
            room.out_event self
          end
        end
      end
    end
  end
end
