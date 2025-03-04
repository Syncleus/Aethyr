require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Hi
        class HiCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_player "\"Hi!\" you greet those around you."
                to_other "#{player.name} greets those around with a \"Hi!\""
              end

              self_target do
                player.output "Hi."
              end

              target do
                to_player "You say \"Hi!\" in greeting to #{self.target.name}."
                to_target "#{player.name} greets you with a \"Hi!\""
                to_other "#{player.name} greets #{self.target.name} with a hearty \"Hi!\""
              end
            end

          end

        end
      end
    end
  end
end
