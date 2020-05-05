require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Frown
        class FrownCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do
              no_target do
                to_player "The edges of your mouth turn down as you frown."
                to_other "The edges of #{player.name}'s mouth turn down as #{player.pronoun} frowns."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player "You frown sadly at yourself."
                to_other "#{player.name} frowns sadly at #{event.target.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You frown at #{event.target.name} unhappily."
                to_target "#{player.name} frowns at you unhappily."
                to_deaf_target event[:to_target]
                to_other "#{player.name} frowns at #{event.target.name} unhappily."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
