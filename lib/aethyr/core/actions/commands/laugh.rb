require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Laugh
        class LaughCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              self_target do
                to_player "You laugh heartily at yourself."
                to_other "#{player.name} laughs heartily at #{player.pronoun(:reflexive)}."
                to_blind_other "Someone laughs heartily."
              end

              target do
                to_player "You laugh at #{event.target.name}."
                to_target "#{player.name} laughs at you."
                to_other "#{player.name} laughs at #{event.target.name}"
                to_blind_target "Someone laughs in your direction."
                to_blind_other "You hear someone laughing."
              end

              no_target do
                to_player "You laugh."
                to_other "#{player.name} laughs."
                to_blind_other "You hear someone laughing."
                to_deaf_other "You see #{player.name} laugh."
              end
            end

          end

        end
      end
    end
  end
end
